CLASS zbg_balance_conf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single_tx_uncontr.
    INTERFACES if_serializable_object.

    METHODS constructor
      IMPORTING
        iv_bill  TYPE zde_out_payment
        iv_m_ind TYPE abap_boolean
        iv_comp  TYPE bukrs
        iv_year  TYPE budat
        iv_docno TYPE belnr_d
        iv_datee TYPE budat.

  PROTECTED SECTION.
    DATA: im_bill   TYPE zde_out_payment,
          im_ind    TYPE abap_boolean,
          im_comp   TYPE bukrs,
          im_year   TYPE budat,
          im_docno  TYPE belnr_d,
          im_dateee TYPE budat.

    METHODS modify RAISING cx_bgmc_operation.

ENDCLASS.


CLASS zbg_balance_conf IMPLEMENTATION.

  METHOD constructor.
    im_bill   = iv_bill.
    im_ind    = iv_m_ind.
    im_comp   = iv_comp.
    im_year   = iv_year.
    im_docno  = iv_docno.
    im_dateee = iv_datee.
  ENDMETHOD.

  METHOD if_bgmc_op_single_tx_uncontr~execute.
    modify( ).
  ENDMETHOD.

  METHOD modify.

    DATA: wa_data  TYPE ztb_bal_conf,
          lv_msg   TYPE string,
          lv_email TYPE string.

    " ═══════════════════════════════════════════════
    " CASE 1 : ZPRINT clicked → Generate and Save PDF
    " ═══════════════════════════════════════════════
    IF im_ind = abap_false.

      DATA lo_pfd TYPE REF TO zcl_balance_conf.

      CREATE OBJECT lo_pfd
        EXPORTING
          iv_datee = im_dateee.

      lo_pfd->get_pdf_64(
        EXPORTING
          io_accountingdoc = im_docno
          io_companycode   = im_comp
          io_customer      = im_bill
          io_postingdate   = im_year
        RECEIVING
          pdf_64 = DATA(pdf_64)
      ).

      IF pdf_64 IS INITIAL.
        RETURN.  " PDF generation failed
      ENDIF.

      " ✅ Save PDF base64 to table
      wa_data-accountingdocument = im_docno.
      wa_data-companycode        = im_comp.
      wa_data-customer           = im_bill.
      wa_data-postingdate        = im_year.
      wa_data-postingdateee      = im_dateee.
      wa_data-base64             = pdf_64.
      wa_data-m_ind              = abap_false.

      MODIFY ztb_bal_conf FROM @wa_data.

    ENDIF.

    " ═══════════════════════════════════════════════
    " CASE 2 : ZSENDMAIL clicked → Read PDF and Send
    " ═══════════════════════════════════════════════
    IF im_ind = abap_true.

      DATA lv_saved_pdf TYPE string.

      " ✅ Read saved base64 PDF from table
      SELECT SINGLE base64
        FROM ztb_bal_conf
        WHERE accountingdocument = @im_docno
          AND companycode        = @im_comp
          AND customer           = @im_bill
        INTO @lv_saved_pdf.

      IF lv_saved_pdf IS INITIAL.
        " PDF not found — generate fresh
        DATA lo_pfd2 TYPE REF TO zcl_balance_conf.

        CREATE OBJECT lo_pfd2
          EXPORTING
            iv_datee = im_dateee.

        lo_pfd2->get_pdf_64(
          EXPORTING
            io_accountingdoc = im_docno
            io_companycode   = im_comp
            io_customer      = im_bill
            io_postingdate   = im_year
          RECEIVING
            pdf_64 = lv_saved_pdf
        ).
      ENDIF.

      IF lv_saved_pdf IS INITIAL.
        RETURN.  " nothing to send
      ENDIF.

      " ✅ Get customer email
      SELECT SINGLE emailaddress
        FROM i_addressemailaddress_2
        WITH PRIVILEGED ACCESS
        WHERE addressid IN (
          SELECT addressnumber
            FROM i_businesspartneraddressusage
            WHERE businesspartner = @im_bill
        )
        INTO @lv_email.

      IF lv_email IS INITIAL.
        SELECT SINGLE emailaddress
          FROM i_addressemailaddress_2
          WITH PRIVILEGED ACCESS
          WHERE addressid IN (
            SELECT independentaddressid
              FROM i_businesspartner
              WHERE businesspartner = @im_bill
          )
          INTO @lv_email.
      ENDIF.

      " ✅ Send mail with saved PDF
      zcl_balance_mail=>send_mail(
        EXPORTING
          iv_customer      = im_bill
          iv_companycode   = im_comp
          iv_accountingdoc = im_docno
          iv_postingdate   = im_year
          iv_datee         = im_dateee
          iv_pdf64         = lv_saved_pdf   " ✅ pass saved PDF
          iv_email         = lv_email
        IMPORTING
          ev_message       = lv_msg
      ).

      " ✅ Update send status in table
      UPDATE ztb_bal_conf
        SET send_mail = @lv_msg
        WHERE accountingdocument = @im_docno
          AND companycode        = @im_comp
          AND customer           = @im_bill.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
