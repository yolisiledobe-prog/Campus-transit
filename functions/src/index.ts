import { createHash } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

if (getApps().length === 0) {
  initializeApp();
}

const firestore = getFirestore();

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => {
    const entities: Record<string, string> = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      "\"": "&quot;",
      "'": "&#39;",
    };
    return entities[character];
  });
}

async function queueEmail(
  eventId: string,
  eventType: string,
  email: string,
  subject: string,
  text: string,
  html: string,
  logContext: Record<string, string>,
): Promise<void> {
  const mailId = createHash("sha256")
    .update(`${eventType}:${eventId}`)
    .digest("hex");
  const mailDocument = firestore.collection("mail").doc(mailId);
  try {
    await mailDocument.create({
      to: email,
      message: { subject, text, html },
    });
    logger.info("Queued email.", logContext);
  } catch (error) {
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error.code === 6 || error.code === "already-exists")
    ) {
      logger.info("Email was already queued.", logContext);
      return;
    }
    throw error;
  }
}

export const emailOnStudentAccountCreated = onDocumentCreated(
  {
    document: "users/{userId}",
    retry: true,
  },
  async (event) => {
    const user = event.data?.data();
    if (!user || user.role !== "student") return;

    const email = typeof user.email === "string" ? user.email.trim() : "";
    if (!email) {
      logger.error("New student account email has no recipient.", {
        userId: event.params.userId,
      });
      return;
    }

    const name = [user.firstName, user.lastName]
      .filter(
        (part): part is string =>
          typeof part === "string" && part.trim().length > 0,
      )
      .map((part) => part.trim())
      .join(" ");
    const greetingName = name || "Student";
    const text = [
      `Hello ${greetingName},`,
      "",
      "Your Campus Transit account has been created successfully.",
      "You can now sign in to apply for student transport and track your application.",
    ].join("\n");
    const html = [
      `<p>Hello ${escapeHtml(greetingName)},</p>`,
      "<p>Your Campus Transit account has been created successfully.</p>",
      "<p>You can now sign in to apply for student transport and track your application.</p>",
    ].join("");

    await queueEmail(
      event.id,
      "student-account-created",
      email,
      "Your Campus Transit account is ready",
      text,
      html,
      { userId: event.params.userId },
    );
  },
);

export const emailOnApplicationDecision = onDocumentUpdated(
  {
    document: "transport_applications/{applicationId}",
    retry: true,
  },
  async (event) => {
    const before = event.data?.before.data();
    const application = event.data?.after.data();
    if (!before || !application) return;

    const status = application.status;
    if (
      before.status === status ||
      (status !== "Approved" && status !== "Rejected")
    ) {
      return;
    }

    const userId = application.uid;
    let email = typeof application.email === "string"
      ? application.email.trim()
      : "";
    if (!email && typeof userId === "string" && userId.length > 0) {
      const userSnapshot = await firestore.collection("users").doc(userId).get();
      const userEmail = userSnapshot.get("email");
      email = typeof userEmail === "string" ? userEmail.trim() : "";
    }
    if (!email) {
      logger.error("Application decision email has no recipient.", {
        applicationId: event.params.applicationId,
      });
      return;
    }

    const fullName =
      typeof application.fullName === "string" &&
      application.fullName.trim().length > 0
        ? application.fullName.trim()
        : "Student";
    const adminComment =
      typeof application.adminComment === "string"
        ? application.adminComment.trim()
        : "";
    const isApproved = status === "Approved";
    const subject = `Campus Transit application ${status.toLowerCase()}`;
    const decisionText = isApproved
      ? "Your transport application has been approved."
      : "Your transport application has been rejected.";
    const commentText = adminComment
      ? `Message from the transport team: ${adminComment}`
      : "";
    const text = [
      `Hello ${fullName},`,
      "",
      decisionText,
      commentText,
      "",
      "Sign in to Campus Transit to view your application status.",
    ]
      .filter(Boolean)
      .join("\n");
    const html = [
      `<p>Hello ${escapeHtml(fullName)},</p>`,
      `<p>${escapeHtml(decisionText)}</p>`,
      adminComment
        ? `<p><strong>Message from the transport team:</strong> ${escapeHtml(adminComment)}</p>`
        : "",
      "<p>Sign in to Campus Transit to view your application status.</p>",
    ]
      .filter(Boolean)
      .join("");

    await queueEmail(
      event.id,
      "application-decision",
      email,
      subject,
      text,
      html,
      {
        applicationId: event.params.applicationId,
        status,
      },
    );
  },
);
