CLASS zcl_email_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.

CLASS zcl_email_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA lv_companycode   TYPE bukrs   VALUE '1000'.
    DATA lv_customer      TYPE kunnr   VALUE 'NAGTR003'.
    DATA lv_accountingdoc TYPE belnr_d VALUE '9400000004'.
    DATA lv_postingdate   TYPE budat   VALUE '20260409'.
*    DATA lv_test_email    TYPE string  VALUE 'isha.tiwari@expoundtechnivo.com'.
 DATA lv_test_email    TYPE string  VALUE 'sahil.mohite@expoundtechnivo.com'.
    DATA lv_message TYPE string.

    zcl_balance_mail=>send_mail(
      EXPORTING
        iv_companycode   = lv_companycode
        iv_customer      = lv_customer
        iv_accountingdoc = lv_accountingdoc
        iv_postingdate   = lv_postingdate

      IMPORTING
        ev_message       = lv_message
    ).

    COMMIT WORK.
    out->write( 'Email trigger executed.' ).
    out->write( lv_message ).

  ENDMETHOD.

ENDCLASS.
