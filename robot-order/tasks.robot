*** Settings ***
Documentation   Download the parameters
...             Open the csv file and enter the values in the form
...             Preview the robot
...             Embed the screenshot of the robot into the pdf
...             Make a zip file for all the saves pdfs
Library     RPA.Browser
Library     RPA.HTTP
Library     RPA.Excel.Files
Library     RPA.Tables
LIbrary     RPA.PDF
Library     RPA.Archive
Library     RPA.Dialogs
LIbrary     RPA.Robocloud.Secrets


*** Keywords ***
Open the Browser
    ${secrets}=     Get Secret      credentials
    Open Available Browser      ${secrets}[link]

***Keywords***
Click ok on the popup
    Click Button       OK

***Keywords***
Download the file
    Create Form     Enter the ULR of the file to be downloaded
    Add Text Input      ULR     url     https://robotsparebinindustries.com/orders.csv
    ${link}     Request Response
    Download     ${link["url"]}     overwrite=True
    ${orders}=      Read Table From CSV     orders.csv
    [return]    ${orders}

***Keywords***
Fill the form
    [Arguments]     ${order}
    Select From List By Value       id:head     ${order}[Head]
    Click Button   ${order}[Body]
    Input Text      class:form-control      ${order}[Legs]
    ${address}=     Convert To String       ${order}[Address]
    Input Text      id:address      ${address}

***Keywords***
Preview the robot
    Click Button        id:preview

***Keywords***
Submit the order
    Click Button    id:order
    Sleep       2 sec

***Keywords***
Go to the next robot
    Click Button        id:order-another

***Variables***
${repeat_submit}   20

***Keywords***
Take a screenshot
    [Arguments]     ${order}
    ${screenshot}=      Set Variable    ${CURDIR}${/}output${/}${order}[Order number].png
    Screenshot      id:robot-preview-image      ${screenshot}
    [return]    ${screenshot}

***Keywords***
Save the pdf
    [Arguments]     ${order}
    ${receipt_in_html}=     Get Element Attribute       id:receipt      outerHTML
    ${pdf}=     Set Variable        ${CURDIR}${/}output${/}${order}[Order number].pdf
    Html To Pdf     ${receipt_in_html}      ${pdf}
    [return]    ${pdf}

*** Keywords ***
Add the image to the pdf
    [Arguments]    ${screenshot}    ${pdf}
    ${s}=   Create List     ${pdf}      ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${s}    ${pdf}
    Close Pdf   ${pdf}

***Keywords***
Archive the order details
    Archive Folder With Zip     ${CURDIR}${/}output     reciepts.zip

*** Tasks ***
Ordering the robots and saving the reciept as a zip file
    ${orders}=      Download the file
    Open the Browser
    FOR     ${row}      IN      @{orders}
        Click ok on the popup
        Fill the form       ${row}
        preview the robot
        Submit the order
        FOR     ${i}    IN RANGE    ${repeat_submit}
            ${receipt_count}=   Get Element Count   id:receipt
            Exit For Loop If    ${receipt_count}>0
            IF     ${receipt_count}<1
                Submit the order
            END
        END
        ${screenshot}=      Take a screenshot   ${row}
        ${pdf}=     Save the pdf    ${row}
        Add the image to the pdf    ${screenshot}   ${pdf}
        Go to the next robot
        Sleep   1 sec
    END
    Archive the order details
    Close Browser
