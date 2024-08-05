*** Settings ***
Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             OperatingSystem
Library             RPA.Robocorp.Process

*** Variables ***
${URL}    https://robotsparebinindustries.com/#/robot-order
${CSV_FILE}    orders.csv
${ZIP_FILE}    ${OUTPUT_DIR}/PDFs.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download orders CSV file
    Create orders from CSV file
    Create ZIP archive

*** Keywords ***
Open the robot order website
    Open Browser    ${URL}    firefox
    Set Window Size    1920    1080

Close modal pop-up
    Wait Until Element Is Visible    xpath=//div[@class='modal']
    Click Button    xpath=//button[contains(text(),'OK')]

Download orders CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Create orders from CSV file
    ${orders}=    Read table from CSV    ${CSV_FILE}    header=True
    FOR    ${order}    IN    @{orders}
        Create order    ${order}
    END

Create order
    [Arguments]    ${order}
    Close modal pop-up
    Select From List By Value    id:head    ${order['Head']}
    Select Radio Button    body    ${order['Body']}
    Input Text    xpath=//input[@placeholder='Enter the part number for the legs']    ${order['Legs']}
    Input Text    id:address    ${order['Address']}
    Click Button    preview
    Wait Until Element Is Visible    id=robot-preview-image
    Retry Submit order
    Take a screenshot of the robot    ${order['Order number']}
    Store the receipt as a PDF file    ${order['Order number']}
    Merge screenshot into PDF    ${order['Order number']}
    Wait And Click Button    order-another

Submit order
    Click Button    order

Retry Submit Order
    ${retry_count}=    Set Variable    0
    WHILE    ${retry_count} < 5
        Submit order
        ${is_error_visible}=    Run Keyword And Return Status    Element Should Be Visible    xpath=//div[@class='alert alert-danger']
        Exit For Loop If    not ${is_error_visible}
        Sleep    2s
        ${retry_count}=    Set Variable    ${retry_count} + 1
    END

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_image_${Order number}.png

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}order_receipt_${Order number}.pdf

Merge screenshot into PDF
    [Arguments]    ${Order number}
    Add Watermark Image To PDF    image_path=${OUTPUT_DIR}${/}robot_image_${Order number}.png    source_path=${OUTPUT_DIR}${/}order_receipt_${Order number}.pdf    output_path=${OUTPUT_DIR}${/}final_order_${Order number}.pdf

Create ZIP archive
    Archive Folder With Zip    ${OUTPUT_DIR}    ${ZIP_FILE}    include=final_order_*.pdf
