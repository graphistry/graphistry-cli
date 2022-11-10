# OIDC Server Setup

## OKTA SETUP

### OKTA OIDC SETUP
| Step | Diagram |
| :- | :-: |
| 1. After login to your OKTA account, if it show this page, click admin button    | <img src="img/OIDC_setup/oidc_setup_okta_1_1.png" width="70%">     |
| 2. Go to the application page and click “Create App Integration” to create a new application.    | <img src="img/OIDC_setup/oidc_setup_okta_1_2.png" width="70%"> |
| 3. Select “OIDC - OpenID Connect” in the Sign-in method section and “Single-Page Application” at the Application Type section.    | <img src="img/OIDC_setup/oidc_setup_okta_1_3.png" width="70%"> | 
| 4. Change the application name as you like and you can upload a logo for this application.    | <img src="img/OIDC_setup/oidc_setup_okta_1_4.png" width="70%"> | 
| 5. Change the sign-in redirect url in the following format. Change the field in bracket to relative field. For example, this is one of the urls used in development eg(http://localhost:8000/o/{org_id}/sso/oidc/{idp_name}/login/callback)
If you are using an enterprise plan, this is the callback url for it. eg(http://localhost:8000/g/sso/oidc/{idp_name}/login/callback)    | <img src="img/OIDC_setup/oidc_setup_okta_1_5.png" width="70%"> | 
| 6. Choose “Skip group assignment for now” and save the changes. We will assign the user/group later.    | <img src="img/OIDC_setup/oidc_setup_okta_1_6.png" width="70%"> | 
| 7. Record the field named “Client ID”, and “Okta domain”. We have to use these fields to register an Organization SSO ID Provider in graphistry.    | <img src="img/OIDC_setup/oidc_setup_okta_1_7.png" width="70%"> <img src="img/OIDC_setup/oidc_setup_okta_1_8.png" width="70%"> | 
| 8. Assign persons to application.    | <img src="img/OIDC_setup/oidc_setup_okta_1_9.png" width="70%"> | 
| 9. Click the “Assign” same line with the person to assign the application to it.    | <img src="img/OIDC_setup/oidc_setup_okta_1_10.png" width="70%"> | 
| 10. Click the “Assign” same line as group to assign group to it. If assigned by group, all people in the group can login to this application.    | <img src="img/OIDC_setup/oidc_setup_okta_1_11.png" width="70%"> | 


1. After login to your OKTA account, if it show this page, click admin button
![image](https://user-images.githubusercontent.com/93269128/200738202-27781a68-e1ea-4509-875c-0dba5aef5704.png)
2. Go to the application page and click “Create App Integration” to create a new application.
![image](https://user-images.githubusercontent.com/93269128/159424300-ebc34710-aaff-4fdd-b255-2d1401ae8156.png)
3. Select “OIDC - OpenID Connect” in the Sign-in method section and “Single-Page Application” at the Application Type section.	
![image](https://user-images.githubusercontent.com/93269128/200738647-ade0ad26-28aa-4ebd-b240-c692d74ae9aa.png)
4. Change the application name as you like and you can upload a logo for this application.
![image](https://user-images.githubusercontent.com/93269128/200741176-b1da3776-b70a-46f5-8716-7f9a3ee15685.png)
5. Change the sign-in redirect url in the following format. Change the field in bracket to relative field. For example, this is one of the urls used in development eg(http://localhost:8000/o/{org_id}/sso/oidc/{idp_name}/login/callback)
If you are using an enterprise plan, this is the callback url for it. eg(http://localhost:8000/g/sso/oidc/{idp_name}/login/callback)
![image](https://user-images.githubusercontent.com/93269128/159429137-6f13cdd9-3306-4f3e-b1f0-b3abae1ee8ea.png)
6. Choose “Skip group assignment for now” and save the changes. We will assign the user/group later.	
![image](https://user-images.githubusercontent.com/93269128/159429177-a507b2bd-6b63-4aac-9694-f4ff98356795.png)
7. Record the field named “Client ID”, and “Okta domain”. We have to use these fields to register an Organization SSO ID Provider in graphistry.	
![image](https://user-images.githubusercontent.com/93269128/200978082-7ab578a9-e6d6-4f9c-9c5e-d67b5c9187b8.png)
![image](https://user-images.githubusercontent.com/93269128/200978359-0b6fc650-61cf-4489-8efa-5617e4feab12.png)
8. Assign persons to application. 
![image](https://user-images.githubusercontent.com/93269128/200741383-78a50796-bbee-4788-be9f-e608b7c1a95c.png)
9. Click the “Assign” same line with the person to assign the application to it. 
![image](https://user-images.githubusercontent.com/93269128/200741506-8dfdb745-af04-4f5f-a921-5429d4f60acd.png)
10. Click the “Assign” same line as group to assign group to it. If assigned by group, all people in the group can login to this application. 
![image](https://user-images.githubusercontent.com/93269128/200741698-a50cfb3c-d95d-45fc-bc0d-6784eda1d694.png)

### OKTA PEOPLE SETUP

1. Create new people.
![image](https://user-images.githubusercontent.com/93269128/200742866-343db4c5-c0be-4b18-bcc1-a7e884be0512.png)
2. Fill in the relative field.If the Activation is set to "Activate later", users will receive an email to set their password and activate the account.
![image](https://user-images.githubusercontent.com/93269128/200743304-a3dee19b-5991-44a1-a44f-c0449005bdf8.png)
3. If the Activation is set to "Activate now", it will show some options for setting the password. If the "I will set password" option is ticked, you can enter a temporary password and can specify user to change their password after first login or not.
![image](https://user-images.githubusercontent.com/93269128/200754546-3ab07d68-f246-4f61-b192-835c84b529a8.png)

### OKTA GROUP SETUP

1. Create a new Group.  
![image](https://user-images.githubusercontent.com/93269128/200758216-cce03795-e0d3-44fa-83fa-43fa2ec5702b.png)
2. Give a name to the group and add description if you want to.  
![image](https://user-images.githubusercontent.com/93269128/200758516-6c12f22c-6b08-4ca7-95f3-3dd8fb94cf12.png)
3. Click the group name you create to manage the group.  
![image](https://user-images.githubusercontent.com/93269128/200758916-dbf62e54-cc4e-4b53-8a1a-a9f25799caeb.png)
4. Click the "Assign people" to add person to the group by clicking the person. You also can remove user from group by click "remove".
![image](https://user-images.githubusercontent.com/93269128/200759364-4079f96a-b03c-4805-a18c-a7613384f0de.png)
![image](https://user-images.githubusercontent.com/93269128/200759757-f29d297a-a514-40cf-b964-f4a9712bb05b.png)


## AUTH0 SETUP

### AUTH0 OIDC SETUP

1. After signing an account for Auth0, select “Company” as the account type so you can limit the person who can log in to this organization. Fill in the company name and select size for company.	
![image](https://user-images.githubusercontent.com/93269128/159425323-b0b2d57c-bfed-4887-aebd-7a4e54919d20.png)
2. You can change the domain name and choose the country you want. Change of country will change the host url. 
![image](https://user-images.githubusercontent.com/93269128/159425368-8f7b0fa1-9106-4c51-a4c6-eed5e7586da2.png)
3. Click the “Application” in the Application section to go to the application page. Click “Create Application” to create a new application. 
![image](https://user-images.githubusercontent.com/93269128/159425549-6be44aa8-b678-4ab9-be96-aa7536760c33.png)
4. Name your application and select “Single Page Web Applications”. 
![image](https://user-images.githubusercontent.com/93269128/200610755-2c4f973c-1125-4c39-9663-0bb7996ad7ec.png)
5. Go to “Settings” to get “Domain”, “Client ID” and “Client Secret”.  We have to use these fields to register an Organization SSO ID Provider in graphistry.	
![image](https://user-images.githubusercontent.com/93269128/159425498-5d8db17d-418e-4618-a7f8-af0ada9ce6a5.png)
6. Change the sign-in redirect url in the following format. Change the field in bracket to relative field. For example, this is one of the urls used in development http://localhost:8000/o/admin/sso/oidc/test_admin/login/callback/ 
If you are using an enterprise plan, this is the callback url for it. http://localhost:8000/g/sso/oidc/Site_wide_SSO_Provider/login/callback/ 
![image](https://user-images.githubusercontent.com/93269128/159430424-cfae2dbf-2346-4a0f-bfa6-dfda485433ca.png)
7. Save changes after completing add callback urls.
8. Disable grants to use organization function. 
![image](https://user-images.githubusercontent.com/93269128/159425667-1da0d918-d729-41ed-9d8f-05af4e9929a2.png)
9. Change the Organization setting to “Team members of organizations” and click “Save Changes“. 
![image](https://user-images.githubusercontent.com/93269128/159425673-2c41e39d-3a46-41da-9428-f0127f60b8f3.png)


### AUTH0 USER SETUP

1. Go to ”User Management” and select the user to go to the user page. Click “Create User” to create a new user. 
![image](https://user-images.githubusercontent.com/93269128/159425732-0a9052e1-b1a1-40ad-94af-4d82c3a88110.png)
2. Fill in all of the fields and click “Create” to create a new user. 
![image](https://user-images.githubusercontent.com/93269128/159425784-ef15759e-bb20-415d-b712-d65ac689dbe3.png)

### AUTH0 ORGANIZATION SETUP

1. Go to “Organizations” and click “Create Organization” to create a new organization. 	
![image](https://user-images.githubusercontent.com/93269128/159425859-295b9e3b-1c59-4474-9697-07da4db63371.png)
2. Name your organization and a name displayed.
![image](https://user-images.githubusercontent.com/93269128/159425894-3a75a592-df49-459b-a68e-0794aab9dd9e.png)
3. Please record this “Organization ID” because this ID has to use when create org sso id provider. 	
![image](https://user-images.githubusercontent.com/93269128/159425928-da97e42b-cfb3-457e-ac29-34f7a67fff92.png)
4. You can change these fields to adjust thein UI the login page. Save changes if you change anything.	
![image](https://user-images.githubusercontent.com/93269128/159426034-79bf463c-7af6-4490-a7fe-449aab4b9fb0.png)
5. Go to the “Member” session and click “Add Members” to add members to your organization. 
![image](https://user-images.githubusercontent.com/93269128/159426219-9324b591-247c-4bd4-ad5b-2d2dab4188d0.png)	
6. After selecting the user you want to add, click “Add Member” to add them to the organization.
![image](https://user-images.githubusercontent.com/93269128/159426220-158eeab4-cb8c-4222-8c86-e087d8d64d0d.png)
7. Go to "Connections" session and click "Enable Connections" to add connections to organization.
![image](https://user-images.githubusercontent.com/93269128/200621154-9b8e4e11-ac1a-44f8-afc2-19b9f8a6ce49.png)
8. Select "Username-Password-Authentication" and click "Enable Connection".
![image](https://user-images.githubusercontent.com/93269128/200621448-e8314aff-21a8-4473-af76-5483c4695d6d.png)


## KEYCLOAK SETUP

### KEYCLOAK OIDC SERVER SETUP

1. Login to the keycloak admin console. Default username is “admin” and passwords is “graphistry”. 
![image](https://user-images.githubusercontent.com/93269128/159426304-a01f6b8c-9f89-44a2-8444-2461a29431b3.png)
2. Create a new realm for OIDC server. Move your mouse cursor to “Master” and the “add realm” button will show up. 	
![image](https://user-images.githubusercontent.com/93269128/159426330-77565558-21a6-4728-bc05-f9c9d725ff99.png)
3. Add a name to this realm. We will take this realm name as idp name when you create an OrgSSO object.  
![image](https://user-images.githubusercontent.com/93269128/159426391-4ae066e9-25ed-47e7-bebc-c1c9e828528d.png)
4. After realm creation success, go to the “clients” section and click “create” to create a new client for OIDC. 
![image](https://user-images.githubusercontent.com/93269128/159426431-c9a35a2e-4921-429a-a992-a5c2ffe79484.png)
5. Fill in “client id” for and this client id is the Client ID you have to use when create OrgSSO object. 	
![image](https://user-images.githubusercontent.com/93269128/159426465-6aa16545-d17c-412b-99d8-fcde0ffef4e8.png)
6. Change the “Access type” from public to confidential. Add valid Redirect URls to it. For example, http://localhost/* , the * means it will take anything after the host. 
![image](https://user-images.githubusercontent.com/93269128/159427116-3cec5c80-17c4-4f68-b6dd-19d9555b32b5.png)
7. Go to “Credentials” to get the secret key. 
![image](https://user-images.githubusercontent.com/93269128/159427136-750a7871-8a7d-4a99-addf-7dba20da1321.png)

### KEYCLOAK USER SETUP
1. Go to the “User” section and click “add user”. 
![image](https://user-images.githubusercontent.com/93269128/159428087-b1d5d007-d05f-4efb-9ba7-620fcddef3d3.png)
2. Fill in the info when you create a user. Only username attribute is required. For the “Required User Actions” attribute, you can choose the action for the user to verify their email or update password for the first time they login. 	
![image](https://user-images.githubusercontent.com/93269128/159428098-43149222-3d06-4ea5-9ef2-5479ece94133.png)
3. Go to the “Credentials” section, create a password for this user so they can log in to this server. If you toggle on the “Temporary”, users have to update the password for the first time they login.	
![image](https://user-images.githubusercontent.com/93269128/159428124-7cb25009-2cf8-4165-980f-0ac39462d606.png)
