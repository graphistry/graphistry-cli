# OIDC Server Setup

## Table of contents
1. [OKTA SETUP](#okta-setup)
    1. [OKTA OIDC SETUP](#okta-oidc-setup)
    2. [OKTA PEOPLE SETUP](#okta-people-setup)
    3. [OKTA GROUP SETUP](#okta-group-setup)
2. [AUTH0 SETUP](#auth0-setup)
    1. [AUTH0 OIDC SETUP](#auth0-oidc-setup)
    2. [AUTH0 USER SETUP](#auth0-user-setup)
    3. [AUTH0 ORGANIZATION SETUP](#auth0-organization)
3. [KEYCLOAK SETUP](#keycloak-setup-no-pkce)
    1. [KEYCLOAK OIDC SERVER SETUP](#keycloak-setup-no-pkce)
    2. [KEYCLOAK USER SETUP](#keycloak-user-setup)
4. [GRAPHISTRY SETUP](#graphistry-setup)
    1. [ORGANIZATION CONFIGURE SSO ](#organization-configure-sso)

<hr>

## OKTA SETUP 

### OKTA OIDC SETUP

1. After logging in your OKTA account, if it show this page, click admin button. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_1.png">

2. Go to the application page and click “Create App Integration” to create a new application. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_2.png">

3. Select “OIDC - OpenID Connect” in the Sign-in method section and “Single-Page Application” at the Application Type section. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_3.png">

4. Change the application name as you like and you can upload a logo for this application. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_4.png">

5. <a name="okta_1_1_5"></a> Change the sign-in redirect url in the following format. Change the field in bracket to relative field. For example, this is one of the urls used in development `http://localhost:8000/o/{organization_id}/sso/oidc/{idp_name}/login/callback`
If you are using an enterprise plan, this is the callback url for it. `http://localhost:8000/g/sso/oidc/{idp_name}/login/callback` <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_5.png">

6. Choose “Skip group assignment for now” and save the changes. We will assign the user/group later. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_6.png">

7. Record the field named “Client ID”, and “Okta domain”. Using these fields allows you to register an Organization SSO ID Provider in Graphistry.  <a name="okta_1_1_7"></a> <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_7.png">
<img src="img/OIDC_setup/oidc_setup_okta_1_8.png">

8. Assign persons to application. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_9.png">

9. Click “Assign” on the line of the person you want to assign the application. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_10.png">

10. Click “Assign” on the line of the group you want to assign the application. If assigned by group, all people in the group can login to this application. <br>
<img src="img/OIDC_setup/oidc_setup_okta_1_11.png">


### OKTA PEOPLE SETUP

1. Add a new person. <br>
<img src="img/OIDC_setup/oidc_setup_okta_2_1.png">

2. Fill in the relative field. If the Activation is set to "Activate later", users will receive an email to set their password and activate the account. <br>
<img src="img/OIDC_setup/oidc_setup_okta_2_2.png">

3. If the Activation is set to "Activate now", it will show some options for setting the password. If the "I will set password" option is ticked, you can enter a temporary password and specify if the user changes their password after initial login. <br>
<img src="img/OIDC_setup/oidc_setup_okta_2_3.png">


### OKTA GROUP SETUP

1. Create a new Group. <br>
<img src="img/OIDC_setup/oidc_setup_okta_3_1.png">

2. Give a name to the group. Optionally, you can add a description. <br>
<img src="img/OIDC_setup/oidc_setup_okta_3_2.png">

3. Click the group name you create to manage the group. <br>
<img src="img/OIDC_setup/oidc_setup_okta_3_3.png">

4. Click "Assign people" to add a person to the group. You can also remove user from group by clicking "remove". <br>
<img src="img/OIDC_setup/oidc_setup_okta_3_4.png">
<img src="img/OIDC_setup/oidc_setup_okta_3_5.png">


<hr>

## AUTH0 SETUP

### AUTH0 OIDC SETUP

1. After signing an account for Auth0, select “Company” as the account type so you can restrict who can log in to this organization. Fill in the company's name and select size for company. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_1.png">

2. You can change the domain name and country. Changing the country will change the host url. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_2.png">

3. Click the “Application” in the Application section to go to the application page. Under the application panel, click “Create Application” to create a new application. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_3.png">

4. Name your application and select “Single Page Web Applications”. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_4.png">

5. Go to “Settings” to get “Domain”, “Client ID” and “Client Secret”.  We have to use these fields to register an Organization SSO ID Provider in Graphistry. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_5.png">

6. Change the sign-in redirect url in the following format. Change the field in bracket to relative field. For example, this is one of the urls used in development `http://localhost:8000/o/admin/sso/oidc/test_admin/login/callback/` 
If you are using an enterprise plan, this is the callback url for it. `http://localhost:8000/g/sso/oidc/Site_wide_SSO_Provider/login/callback/` <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_6.png">

7. Save changes after completing add callback urls. <br>

8. Disable grants to use organization function. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_7.png">

9. Change the Organization setting to “Team members of organizations” and click “Save Changes“. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_1_8.png">


### AUTH0 USER SETUP

1. Go to ”User Management” and select the user to go to the user page. Click “Create User” to create a new user. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_2_1.png">

2. Fill in all of the fields and click “Create” to create a new user. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_2_2.png">

### AUTH0 ORGANIZATION

1. Go to “Organizations” and click “Create Organization” to create a new organization. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_1.png">	

2. Name your organization and set your displayed name. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_2.png">	

3. Record your “Organization ID” which you'll need when you create your org sso id provider. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_3.png">	

4. You can change these fields to adjust the UI of the login page. Make sure to save your changes. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_4.png">	

5. Go to the “Member” session and click “Add Members” to add members to your organization. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_5.png">	

6. After selecting the user you want to add, click “Add Member” to add them to the organization. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_6.png">	

7. Go to "Connections" session and click "Enable Connections" to add connections to organization. <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_7.png">	

8. Select "Username-Password-Authentication" and click "Enable Connection". <br>
<img src="img/OIDC_setup/oidc_setup_auth0_3_8.png">	


<hr>

## KEYCLOAK SETUP (No PKCE)

### KEYCLOAK OIDC SERVER SETUP

1. Login to the keycloak admin console. Default username is “admin” and passwords is “graphistry”. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_1.png">	

2. Create a new realm for OIDC server. Move your mouse cursor to “Master” and the “add realm” button will show up. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_2.png">	

3. Add a name to this realm. We will take this realm name as idp name when you create an OrgSSO object. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_3.png">	

4. After realm creation success, go to the “clients” section and click “create” to create a new client for OIDC. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_4.png">	

5. Fill in “client id” for and this client id is the Client ID you have to use when create OrgSSO object. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_5.png">

6. Change the “Access type” from public to confidential. Add valid Redirect URls to it. For example, `http://localhost/*` , the * means it will take anything after the host. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_6.png">

7. Go to “Credentials” to get the secret key. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_1_7.png">

### KEYCLOAK USER SETUP
1. Go to the “User” section and click “add user”. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_2_1.png">	

2. Fill in the info when you create a user. Only username attribute is required. For the “Required User Actions” attribute, you can choose the action for the user to verify their email or update password for the first time they login. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_2_2.png">

3. Go to the “Credentials” section, create a password for this user so they can log in to this server. If you toggle on the “Temporary”, users have to update the password for the first time they login. <br>
<img src="img/OIDC_setup/oidc_setup_keycloak_2_3.png">


<hr>

## GRAPHISTRY SETUP

### ORGANIZATION CONFIGURE SSO

1. After login to your graphistry account, click the "Manage organization" button. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_1.png">

2. Click the "+" button to add a new organization. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_2.png">

3. Fill the information for the organization and click the create button, the "Organization ID" is unique. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_3.png">

4. Click the orange button, which is "configure SSO" button. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_4.png">

5. Click the "+" button to add new SSO providers. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_5.png">

6. Fill the IDP Name, Host URL, Client ID and select the SSO provider. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_6.png">

7. Example for Okta, "Client ID" and "Host URL" can found in [“Client ID”, and “Okta domain”](#okta_1_1_7) respectively. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_7.png">

8. The SSO Provider for the organization was shown. Remember to setup the Sign-in redirect URIs in [picture](#okta_1_1_5), fill it with 
`http://{hostname}/o/{organization_id}/sso/oidc/{idp_name}/login/callback`. <br>
<img src="img/OIDC_setup/oidc_setup_graphistry_1_8.png">
