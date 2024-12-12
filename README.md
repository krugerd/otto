# otto
script for automating bulk user identity actions

## OPTIONS:
        signins
        users
        licenses
        roles

## REMARKS:

> [!IMPORTANT]
> This script automates actions typically done manually through the Entra ID portal and is provided AS-IS.  
> Please review code before running in any environment to understand what it is doing as there is no 'undo'.

Input file format is a text file containing 1 UPN per line for each user account to be modified. For example:

![image](https://github.com/user-attachments/assets/b65ba1cf-4bd0-45d7-9b59-e1349af86058)

## USAGE:
otto.ps1 -do [options]

### otto -do signins:
- creates a spreadsheet of all tenant users showing Display Name, UPN, Account Status (Enabled/Disabled), Last Sign In Date Time, Last Successful Sign In Date Time and Last Non Interactive Sign In Date Time
- can also be used for specific users only provided in an input text file, or users matching a search input (dave*)

### otto -do users:
- add, remove, disable or enable accounts for all users provided in an input file

### otto -do licenses:
- add or remove licenses for all users provided in an input file
- licenses are selected from a GUI inputbox

### otto -do roles:
- add Active, add Eligible, or List all roles assigned to users
- roles are selected from a GUI inputbox
