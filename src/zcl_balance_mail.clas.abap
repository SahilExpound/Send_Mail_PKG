CLASS zcl_balance_mail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS send_mail
      IMPORTING
        iv_customer      TYPE kunnr
        iv_companycode   TYPE bukrs
        iv_accountingdoc TYPE belnr_d
        iv_postingdate   TYPE budat
        iv_datee         TYPE budat   OPTIONAL
        iv_pdf64         TYPE string  OPTIONAL   " ✅ base64 PDF
        iv_email         TYPE string  OPTIONAL   " ✅ email address
      EXPORTING
        ev_message       TYPE string.

ENDCLASS.


CLASS zcl_balance_mail IMPLEMENTATION.

  METHOD send_mail.

    DATA: lv_email TYPE string,
          lv_xstr  TYPE xstring,
          lv_body  TYPE string,
          lv_pdf64 TYPE string.

    " ── STEP 1 : Resolve Email ────────────────────────────────────
    IF iv_email IS NOT INITIAL.
      lv_email = iv_email.
    ELSE.
      SELECT SINGLE emailaddress
        FROM i_addressemailaddress_2
        WITH PRIVILEGED ACCESS
        WHERE addressid IN (
          SELECT addressnumber
            FROM i_businesspartneraddressusage
            WHERE businesspartner = @iv_customer
        )
        INTO @lv_email.

      IF lv_email IS INITIAL.
        SELECT SINGLE emailaddress
          FROM i_addressemailaddress_2
          WITH PRIVILEGED ACCESS
          WHERE addressid IN (
            SELECT independentaddressid
              FROM i_businesspartner
              WHERE businesspartner = @iv_customer
          )
          INTO @lv_email.
      ENDIF.

      IF lv_email IS INITIAL.
        ev_message = |ERROR: No email found for { iv_customer }|.
        RETURN.
      ENDIF.
    ENDIF.

    " ── STEP 2 : Resolve PDF base64 ──────────────────────────────
    IF iv_pdf64 IS NOT INITIAL.

      " ✅ Use passed PDF directly
      lv_pdf64 = iv_pdf64.

    ELSE.

      " Fallback: read from table
      SELECT SINGLE base64
        FROM ztb_bal_conf
        WHERE accountingdocument = @iv_accountingdoc
          AND companycode        = @iv_companycode
          AND customer           = @iv_customer
        INTO @lv_pdf64.

      " Last resort: regenerate
      IF lv_pdf64 IS INITIAL.
        DATA lo_conf TYPE REF TO zcl_balance_conf.
        CREATE OBJECT lo_conf
          EXPORTING
            iv_datee = iv_datee.

        lo_conf->get_pdf_64(
          EXPORTING
            io_companycode   = iv_companycode
            io_customer      = iv_customer
            io_postingdate   = iv_postingdate
            io_accountingdoc = iv_accountingdoc
          RECEIVING
            pdf_64 = lv_pdf64
        ).
      ENDIF.

    ENDIF.

    IF lv_pdf64 IS INITIAL.
      ev_message = |ERROR: PDF empty for doc { iv_accountingdoc }|.
      RETURN.
    ENDIF.

    " ── STEP 3 : Decode base64 → xstring ─────────────────────────
    TRY.
        lv_xstr = cl_web_http_utility=>decode_x_base64( lv_pdf64 ).
      CATCH cx_sy_conversion_error INTO DATA(lx_conv).
        ev_message = |ERROR: Decode failed - { lx_conv->get_text( ) }|.
        RETURN.
    ENDTRY.

    IF lv_xstr IS INITIAL.
      ev_message = 'ERROR: XSTRING empty after decode'.
      RETURN.
    ENDIF.

    " ── STEP 4 : Build Body ───────────────────────────────────────
    lv_body =
      |Dear Sir/Madam,<br><br>| &&
      |For the purpose of Statutory/Internal audit requirement,| &&
      | you are requested to confirm the amounts of dues.<br>| &&
      |Please find the attached Balance Confirmation Letter.<br><br>| &&
      |Thanks &amp; Regards,<br>| &&
      |Accounts Team|.

    " ── STEP 5 : Send ────────────────────────────────────────────
    TRY.
        DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).

        lo_mail->add_recipient(
          iv_address = CONV #( lv_email )
        ).

        lo_mail->set_sender(
          iv_address = 'noreply@yourtenant.mail.s4hana.ondemand.com'
        ).

        lo_mail->set_subject( 'Balance Confirmation Letter' ).

        lo_mail->set_main(
          cl_bcs_mail_textpart=>create_instance(
            iv_content      = lv_body
            iv_content_type = 'text/html'
          )
        ).

        " ✅ Attach PDF
        DATA(lo_att) = cl_bcs_mail_binarypart=>create_instance(
          iv_content      = lv_xstr
          iv_content_type = 'application/pdf'
          iv_filename     = 'Balance_Confirmation.pdf'
        ).

        lo_mail->add_attachment( lo_att ).

        lo_mail->send(
          IMPORTING et_status = DATA(lt_status)
        ).

        ev_message = |SUCCESS: Mail sent to { lv_email }|.

      CATCH cx_bcs_mail INTO DATA(lx_mail).
        ev_message = |MAIL ERROR: { lx_mail->get_text( ) }|.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
