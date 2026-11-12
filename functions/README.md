# Application decision emails

`emailOnStudentAccountCreated` queues a welcome email when a student profile
document is created. `emailOnApplicationDecision` queues an email only when an
application changes to `Approved` or `Rejected`. Both write messages to the
`mail` collection for the Firebase Trigger Email extension to deliver.

## Firebase setup

1. Install the **Trigger Email** Firebase Extension in the
   `campustransit-26c45` project and set its Firestore collection to `mail`.
2. Configure the extension's SMTP connection and sender address in Firebase
   Console. Keep SMTP credentials in the extension's Secret Manager setup; do
   not add them to app code or source control.
3. Enable **Email/Password** in Firebase Authentication and review the
   **Email address verification** and **Password reset** templates. The app
   requests these Firebase Auth emails; Firebase Console settings and
   authorized domains control their delivery.
4. Deploy both functions with the Firebase CLI:

   ```powershell
   firebase deploy --only functions --project campustransit-26c45
   ```

Cloud Functions deployment requires the Firebase project to use the Blaze
plan. The extension must be installed and configured before queued messages
can be delivered. Verify the sender domain and check spam folders when
testing email delivery.
