CLASS lsc_zi_balance_conf DEFINITION INHERITING FROM cl_abap_behavior_saver.

    PUBLIC SECTION.

    CLASS-DATA:
      gt_sendmail TYPE STANDARD TABLE OF sysuuid_x16.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.


ENDCLASS.


CLASS lsc_zi_balance_conf IMPLEMENTATION.

  METHOD save_modified.
  DATA lo_pfd TYPE REF TO zcl_balance_conf.  "<-write your class name
    DATA wa_data TYPE ztb_bal_conf.  "<-write your table name
    CREATE OBJECT lo_pfd.

    IF update-zi_balance_conf_doc IS NOT INITIAL."<-write your interface name

      LOOP AT update-zi_balance_conf_doc INTO DATA(ls_data)."<-write your interface name

        DATA(new) = NEW zbg_balance_conf( iv_docno = ls_data-AccountingDocument iv_comp = ls_data-CompanyCode iv_bill = ls_data-Customer iv_year = ls_data-PostingDate  iv_m_ind = ls_data-m_ind iv_datee = ls_data-postingdateee ).
"<-write your background process class

        DATA background_process TYPE REF TO if_bgmc_process_single_op.
       TRY.


            background_process = cl_bgmc_process_factory=>get_default( )->create( ).

            background_process->set_operation_tx_uncontrolled( new ).

*            IF ls_data-m_ind EQ 'X'.
**                 MOVE-CORRESPONDING ls_data TO wa_data.
*              wa_data-Customer   = ls_data-Customer.
*             wa_data-CompanyCode  = ls_data-CompanyCode.
*             wa_data-PostingDate  = ls_data-PostingDate.
*              wa_data-base64 = ls_data-base64.
*              wa_data-m_ind    = ls_data-m_ind.
*              MODIFY ztb_balance_conf FROM @wa_data.  "<-write your table name
*            ENDIF.

            background_process->save_for_execution( ).

          CATCH cx_bgmc INTO DATA(exception).
            DATA(lv_text) = exception->get_text( ).

            "handle exception
        ENDTRY.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_zi_balance_conf_doc DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZI_balance_conf_doc RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZI_balance_conf_doc RESULT result.

    METHODS zprint FOR MODIFY
      IMPORTING keys FOR ACTION ZI_balance_conf_doc~zprint RESULT result.

    METHODS zsendmail FOR MODIFY           " <-- ADD THIS
      IMPORTING keys FOR ACTION zi_balance_conf_doc~zsendmail
      RESULT result.


ENDCLASS.

CLASS lhc_ZI_balance_conf_doc IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.



*METHOD zsendmail.
*
*  READ ENTITIES OF zi_balance_conf IN LOCAL MODE
*    ENTITY zi_balance_conf_doc
*    ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_data).
*
*  IF lt_data IS INITIAL.
*    RETURN.
*  ENDIF.
*
*  LOOP AT lt_data INTO DATA(ls_data).
*
*    DATA(lo_process) = NEW zbg_balance_conf(
*      iv_docno = ls_data-accountingdocument
*      iv_comp  = ls_data-companycode
*      iv_bill  = ls_data-customer
*      iv_year  = ls_data-postingdate
*      iv_m_ind = abap_true
*      iv_datee = ls_data-postingdateee
*    ).
*
*    TRY.
*
*        DATA(lo_bg) =
*          cl_bgmc_process_factory=>get_default( )->create( ).
*
*        lo_bg->set_operation_tx_uncontrolled( lo_process ).
*
*        lo_bg->save_for_execution( ).
*
*      CATCH cx_bgmc INTO DATA(lx_bg).
*
*    ENDTRY.
*
*  ENDLOOP.
*
*  APPEND VALUE #(
*    %tky = keys[ 1 ]-%tky
*    %msg = new_message_with_text(
*              severity = if_abap_behv_message=>severity-success
*              text     = 'Mail triggered successfully'
*           )
*  ) TO reported-zi_balance_conf_doc.
*
*ENDMETHOD.

METHOD zsendmail.

  DATA: lt_update TYPE TABLE FOR UPDATE zi_balance_conf,
        ls_update TYPE STRUCTURE FOR UPDATE zi_balance_conf.

  READ ENTITIES OF zi_balance_conf IN LOCAL MODE
    ENTITY zi_balance_conf_doc
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_data).

  LOOP AT lt_data INTO DATA(ls_data).

    CLEAR ls_update.

    ls_update-%tky  = ls_data-%tky.
    ls_update-m_ind = abap_true.

    APPEND ls_update TO lt_update.


  ENDLOOP.

  MODIFY ENTITIES OF zi_balance_conf IN LOCAL MODE
    ENTITY zi_balance_conf_doc
    UPDATE FIELDS ( m_ind )
    WITH lt_update
    REPORTED reported
    FAILED failed.

  APPEND VALUE #(
    %tky = keys[ 1 ]-%tky
    %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'Mail request submitted successfully'
           )
  ) TO reported-zi_balance_conf_doc.

ENDMETHOD.

  METHOD zprint.

  DATA lv_id    TYPE ztb_bal_conf-postingdate.

  DATA lo_pfd TYPE REF TO zcl_balance_conf. "<-write your logic class


  CREATE OBJECT lo_pfd.

    READ ENTITIES OF zi_balance_conf IN LOCAL MODE "<-write your interface name
           ENTITY ZI_balance_conf_doc   "<-write your interface name
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(lt_result).

 READ TABLE keys INTO DATA(ls_key) INDEX 1.

    IF sy-subrc = 0.
      lv_id = ls_key-%param-postingdateee.

    ENDIF.

              CREATE OBJECT lo_pfd
              expoRTING
              iv_datee = lv_id.

    LOOP AT lt_result INTO DATA(lw_result).

      DATA : update_lines TYPE TABLE FOR UPDATE  zi_balance_conf,   "<-write your interface name
             update_line  TYPE STRUCTURE FOR UPDATE  zi_balance_conf.   "<-write your interface name

      update_line-%tky                   = lw_result-%tky.
      update_line-base64                 = 'A'.
            update_line-postingdateee                 = lv_id.


      IF update_line-base64 IS NOT INITIAL.

        APPEND update_line TO update_lines.

        MODIFY ENTITIES OF  zi_balance_conf IN LOCAL MODE    "<-write your interface name
         ENTITY ZI_balance_conf_doc   "<-write your interface behaviour definition name
           UPDATE
           FIELDS ( base64  postingdateee )
           WITH update_lines
         REPORTED reported
         FAILED failed
         MAPPED mapped.

        READ ENTITIES OF zi_balance_conf IN LOCAL MODE  ENTITY ZI_balance_conf_doc "<-write your interface name and behaviour definition name
            ALL FIELDS WITH CORRESPONDING #( lt_result ) RESULT DATA(lt_final).

        result =  VALUE #( FOR  lw_final IN  lt_final ( %tky = lw_final-%tky
         %param = lw_final  )  ).

        APPEND VALUE #( %tky = keys[ 1 ]-%tky
                        %msg = new_message_with_text(
                        severity = if_abap_behv_message=>severity-success
                        text = 'PDF Generated!, Please Wait for 30 Sec' )
                         ) TO reported-ZI_balance_conf_doc.    "<-write your interface behaviour definition name

      ELSE.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
