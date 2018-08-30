# Installation

1. Install the program ZABAPGIT on your ABAP system -> https://github.com/larshp/abapGit
1. Start ZABAPGIT, "+online" to add the repository https://github.com/ivanfemia/abap2oauth2, and **pull** it
1. "+online" of the current repository, and **pull** it

# Usage

1. Configure your account to Google APIs
1. Ask your client ID and secret at Google APIs
1. Create an entry in table ZOAUTH2_CONSUMER : consumer, client ID, client secret, signature method (3 for Google Apps), API host, redirect URIs, javascript origin
1. Run the program ZGAPPS_UPLOAD, enter the consumer, choose a file and run the program
1. Go to Google Docs and see your file
