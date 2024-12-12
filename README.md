# otto
script for automating bulk user identity actions

# USAGE:
otto.ps1 -do [options]

# OPTIONS:
        signins
        users
        licenses
        roles

# REMARKS:

This script automates actions typically done manually through the Entra ID portal GUI and is provided AS-IS.  
Please review code before running in any environment to understand what it is doing as there is no 'undo'.

## otto -do signins:
- creates a spreadsheet of all tenant users showing Display Name, UPN, Account Status (Enabled/Disabled), Last Sign In Date Time, Last Successful Sign In Date Time and Last Non Interactive Sign In Date Time
- can also be used for specific users only provided in an input text file, or users matching a search input (dave*)

## otto -do users:
- add, remove, disable or enable accounts for all users provided in an input file

## otto -do licenses:
- add or remove licenses for all users provided in an input file
- licenses are selected from a GUI inputbox

## otto -do roles:
- add Active, add Eligible, or List all roles assigned to users
- roles are selected from a GUI inputbox

> [!IMPORTANT]
> Input file format needs to be a text file only containing 1 UPN per line of the users to be modified.

/jimmy.john@123dev.com
/jimmy.joe@123dev.com
/jimmy.bob@123dev.com

