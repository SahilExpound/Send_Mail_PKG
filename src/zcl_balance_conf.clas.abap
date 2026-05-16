CLASS zcl_balance_conf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS get_pdf_64
      IMPORTING

        VALUE(io_companycode) TYPE i_accountingdocumentjournal-companycode
         VALUE(io_customer)    TYPE i_accountingdocumentjournal-customer
        VALUE(io_postingdate) TYPE i_accountingdocumentjournal-postingdate
        VALUE(io_accountingdoc) TYPE i_accountingdocumentjournal-accountingdocument
      RETURNING
        VALUE(pdf_64)         TYPE string.

    METHODS escape_xml
      IMPORTING
        iv_in         TYPE any
      RETURNING
        VALUE(rv_out) TYPE string.

        METHODS constructor
      IMPORTING
        iv_datee TYPE ztb_bal_conf-postingdateee OPTIONAL.



          METHODS num2words
      IMPORTING
        iv_num          TYPE string
        iv_major        TYPE string
        iv_minor        TYPE string
        iv_top_call     TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_words) TYPE string.


    DATA mv_total TYPE p LENGTH 16 DECIMALS 2.
    DATA mv_drcr  TYPE string.

  PRIVATE SECTION.
    METHODS build_xml
      IMPORTING
        VALUE(io_companycode) TYPE i_accountingdocumentjournal-companycode
         VALUE(io_customer)    TYPE i_accountingdocumentjournal-customer
        VALUE(io_postingdate) TYPE i_accountingdocumentjournal-postingdate
        VALUE(io_accountingdoc) TYPE i_accountingdocumentjournal-accountingdocument
      RETURNING
        VALUE(rv_xml)         TYPE string.

         DATA : mv_date TYPE ztb_bal_conf-postingdateee.
ENDCLASS.



CLASS ZCL_BALANCE_CONF IMPLEMENTATION.


  METHOD escape_xml.
    rv_out = |{ iv_in }|.   " explicit conversion to STRING

    IF rv_out IS INITIAL.
      RETURN.
    ENDIF.

    " Replace must be done in order to avoid double-escaping
    REPLACE ALL OCCURRENCES OF '&' IN rv_out WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_out WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_out WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_out WITH '&quot;'.
  ENDMETHOD.


  METHOD get_pdf_64.
    DATA(lv_xml) = build_xml(
                           io_accountingdoc = io_accountingdoc
                           io_companycode = io_companycode
                           io_customer = io_customer
                           io_postingdate = io_postingdate ).



DATA lv_template TYPE string.

         if     IO_COMPANYCODE = '1000'.
           lv_template = 'ZFI_BALANCE_CONF/ZFI_BALANCE_CONF'.
         elseif IO_COMPANYCODE  = '2000'.
         lv_template   =  'ZFI_BAL_CONF_LTR/ZFI_BAL_CONF_LTR'.
         else.
         lv_template = 'ZFI_BALANCE_CONF/ZFI_BALANCE_CONF'.
         enDIF.



CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = lv_template
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.
      pdf_64 = lv_result.
    ENDIF.

  ENDMETHOD.

  METHOD constructor.

    mv_date = iv_datee.

  ENDMETHOD.


METHOD build_xml.

  DATA: lv_bpname TYPE i_businesspartner-organizationbpname1,
        lv_addr   TYPE i_businesspartner-independentaddressid,
        lv_postal TYPE i_address_2-postalcode,
        lv_region TYPE i_address_2-region,
        lv_street type i_address_2-streetname,
        lv_city type i_address_2-cityname,
        lv_pan    TYPE i_supplier-businesspartnerpannumber,
        lv_total  TYPE p LENGTH 16 DECIMALS 2,
        lv_curr    TYPE i_operationalacctgdocitem-transactioncurrency,
         lv_drcr TYPE string,
        lv_major   TYPE string,
        lv_minor   TYPE string,
        lv_xml    TYPE string,
        lv_fax type string.



DATA:
      lv_year    TYPE n LENGTH 4,
    lv_month   TYPE n LENGTH 2,
    lv_today type string.

    lv_today  = mv_date.



DATA(lv_fmt_date) =
|{ lv_today+6(2) }.{ lv_today+4(2) }.{ lv_today+0(4) }|.


  SELECT SINGLE organizationbpname1
  FROM i_businesspartner
  WHERE businesspartner = @io_customer
  INTO @lv_bpname.


  SELECT SINGLE independentaddressid
  FROM i_businesspartner
  WHERE businesspartner = @io_customer
  INTO @lv_addr.


  IF lv_addr IS NOT INITIAL.
    SELECT SINGLE postalcode, region
    FROM i_address_2
    WHERE addressid = @lv_addr
    INTO (@lv_postal,@lv_region).
  ENDIF.

SELECT SINGLE businesspartnerpannumber
FROM i_supplier
WHERE supplier = @io_customer
INTO @lv_pan.

*DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

DATA lv_first_date TYPE d.

lv_first_date = lv_today.
lv_first_date+6(2) = '01'.

DATA(lv_fmt_posting_date) = |{ lv_first_date+6(2) }.{ lv_first_date+4(2) }.{ lv_first_date+0(4) }|.

lv_year  = io_postingdate+0(4).
  lv_month = io_postingdate+4(2).

  IF lv_month < '04'.
    lv_year = lv_year - 1.
  ENDIF.

  " Format Start Date as 01.04.YYYY
  DATA(lv_fmt_start) = |01.04.{ lv_year }|.

  " Build start date as TYPE d  (YYYYMMDD) for the WHERE clause
  DATA(lv_start_d) = |{ lv_year }0401|.   " e.g. 20250401

*
*SELECT
*       SUM( amountintransactioncurrency ) AS total_amount,
*       transactioncurrency
*FROM i_operationalacctgdocitem
*WHERE customer = @io_customer
*  AND companycode = @io_companycode

*  AND financialaccounttype = 'D'
*  AND ( clearingjournalentry IS INITIAL
*        OR clearingjournalentry = '' )
**  AND PostingDate <= @lv_today
* AND postingdate          >= @lv_start_d        " from FY start
* AND postingdate          <= @io_postingdate
*GROUP BY transactioncurrency
*INTO TABLE @DATA(lt_sum).


SELECT
       SUM( amountintransactioncurrency ) AS total_amount,
       transactioncurrency
FROM i_operationalacctgdocitem
WHERE customer = @io_customer
  AND companycode = @io_companycode
  AND financialaccounttype = 'D'
  AND ( clearingjournalentry IS INITIAL
        OR clearingjournalentry = '' )
  AND postingdate >= @lv_start_d
  AND postingdate <  @mv_date
GROUP BY transactioncurrency
INTO TABLE @DATA(lt_sum).

READ TABLE lt_sum INTO DATA(ls_sum) INDEX 1.

IF sy-subrc = 0.
  lv_total = ls_sum-total_amount.
  lv_curr  = ls_sum-transactioncurrency.
ENDIF.

IF lv_total < 0.
  lv_drcr = 'Cr'.
  lv_total = abs( lv_total ).
ELSE.
  lv_drcr = 'Dr'.
ENDIF.

mv_total = lv_total.



DATA: lv_addressid TYPE i_address_2-addressid.

SELECT SINGLE AddressID
FROM I_CompanyCode
WHERE CompanyCode = @io_companycode
INTO @lv_addressid.

SELECT SINGLE
       OrganizationName1,
       StreetName,
       CityName,
       PostalCode,
       Country,
       Region
FROM Z_I_Address_2
WHERE AddressID = @lv_addressid
INTO @DATA(ls_address).


DATA(lv_address) =
|{ ls_address-OrganizationName1 }, { ls_address-StreetName } \n { ls_address-CityName }- { ls_address-PostalCode }, { ls_address-Country }- { ls_address-Region }|.
***" 1. Fetch current system date
***DATA(lv_system_date) = cl_abap_context_info=>get_system_date( ).
***
***" 2. Format it as DD.MM.YYYY
***DATA(lv_fmt_system_date) = |{ lv_system_date+6(2) }.{ lv_system_date+4(2) }.{ lv_system_date+0(4) }|.
****for date logic
***
***" 2. Calculate the Start Date logic (Financial Year start)
***lv_year  = io_postingdate+0(4).
***lv_month = io_postingdate+4(2).
***
***IF lv_month < '04'.
***  lv_year = lv_year - 1.
***ENDIF.
***
***" Format Start Date as 01.04.YYYY
***DATA(lv_fmt_start) = |01.04.{ lv_year }|.

select siNGLE
       FaxAreaCodeSubscriberNumber
       from
       I_AddressFaxNumber_2
       wiTH PRIVILEGED ACCESS
       where addressid = @lv_addressid
       into (@lv_fax).

       select single
       PhoneAreaCodeSubscriberNumber
       from I_AddressPhoneNumber_2
       witH PRIVILEGED ACCESS
       where addressid = @lv_addressid
       into @data(lv_phno).

    CLEAR: lv_major, lv_minor.
    CLEAR: lv_major, lv_minor.

     CASE lv_curr.

        " -------- RUPEE FAMILY --------
      WHEN 'INR'. lv_major = 'Rupee'.   lv_minor = 'Paise'.
      WHEN 'PKR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'NPR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'LKR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.
      WHEN 'SCR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.

        " -------- DOLLAR FAMILY --------
      WHEN 'USD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'AUD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'CAD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'NZD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'SGD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'HKD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.

        " -------- EURO --------
      WHEN 'EUR'. lv_major = 'Euro'.    lv_minor = 'Cent'.

        " -------- POUND --------
      WHEN 'GBP'. lv_major = 'Pound'.   lv_minor = 'Penny'.

        " -------- YEN / WON (NO MINOR) --------
      WHEN 'JPY'. lv_major = 'Yen'.     lv_minor = ''.
      WHEN 'KRW'. lv_major = 'Won'.     lv_minor = ''.

        " -------- MIDDLE EAST --------
      WHEN 'AED'. lv_major = 'Dirham'.  lv_minor = 'Fils'.
      WHEN 'SAR'. lv_major = 'Riyal'.   lv_minor = 'Halala'.
      WHEN 'QAR'. lv_major = 'Riyal'.   lv_minor = 'Dirham'.
      WHEN 'OMR'. lv_major = 'Rial'.    lv_minor = 'Baisa'.
      WHEN 'KWD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.
      WHEN 'BHD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.

        " -------- ASIA --------
      WHEN 'CNY'. lv_major = 'Yuan'.    lv_minor = 'Fen'.
      WHEN 'THB'. lv_major = 'Baht'.    lv_minor = 'Satang'.
      WHEN 'MYR'. lv_major = 'Ringgit'. lv_minor = 'Sen'.
      WHEN 'IDR'. lv_major = 'Rupiah'.  lv_minor = 'Sen'.
      WHEN 'PHP'. lv_major = 'Peso'.    lv_minor = 'Centavo'.

        " -------- AFRICA --------
      WHEN 'ZAR'. lv_major = 'Rand'.    lv_minor = 'Cent'.
      WHEN 'NGN'. lv_major = 'Naira'.   lv_minor = 'Kobo'.

        " -------- OTHERS / FALLBACK --------
      WHEN OTHERS.
        lv_major = lv_curr.
        lv_minor = ''.

    ENDCASE.

     DATA: lv_amount_string TYPE string.
*     lv_total = abs( lv_total ).

    lv_amount_string = |{  lv_total }|.
    CONDENSE lv_amount_string.

    DATA :  lv_amt_inword TYPE STRING.

      lv_amt_inword = me->num2words(
      iv_num   = lv_amount_string
      iv_major = lv_major
      iv_minor = lv_minor
    ).


    select single * from
    I_AccountingDocumentJournal
    where AccountingDocument = @io_accountingdoc
    and CompanyCode = @io_companycode
    and FinancialAccountType = 'D'
    into @data(wa_customer).

    select single * from
    I_Customer
    where Customer = @wa_customer-Customer
    into @data(cust_addr).

    data(address_c) = |{  cust_addr-OrganizationBPName1 }\n{ cust_addr-StreetName },{ cust_addr-CityCode }{ cust_addr-PostalCode }|.


DATA(lo_process) = NEW zbg_balance_conf(
  iv_bill  = io_customer
  iv_comp  = io_companycode
  iv_docno = io_accountingdoc
  iv_year  = mv_date                "io_postingdate
  iv_datee = mv_date
  iv_m_ind = abap_true
).

rv_xml =
|<form1>| &&
|<Design>| &&

|<Subform1>| &&
*|<date>{ escape_xml( lv_fmt_system_date ) }</date>| &&
|<date>{ escape_xml( lv_fmt_date ) }</date>| &&
|</Subform1>| &&

|<Subform2/>| &&

|<Subform3>| &&
|<to>{ escape_xml( address_c ) }</to>| &&
|<from>{ escape_xml( lv_fmt_posting_date ) }</from>| &&
|<date>{ escape_xml( lv_fmt_date ) }</date>| &&
|</Subform3>| &&

|<FBSubform>| &&
|<date>{ escape_xml( lv_fmt_date ) }</date>| &&
|<dr_cr>{ escape_xml( lv_drcr ) }</dr_cr>| &&
|<amnt>{ escape_xml( lv_total ) }</amnt>| &&
|<cust>{ escape_xml( lv_bpname ) }</cust>| &&
|<pan>{ escape_xml( lv_pan ) }</pan>| &&
|<outdate>{ escape_xml( lv_fmt_date ) }</outdate>| &&
|<rs>{ escape_xml( lv_total ) }</rs>| &&
|<mantinwrds>{ escape_xml( lv_amt_inword ) }</mantinwrds>| &&
|<drcr>{ escape_xml( lv_drcr ) }</drcr>| &&
|</FBSubform>| &&

|<Faddress>{ escape_xml( lv_address ) }</Faddress>| &&
|<tel>{ escape_xml( lv_phno ) }</tel>| &&
|<fax>{ escape_xml( lv_fax ) }</fax>| &&

|</Design>| &&
|</form1>|.

  ENDMETHOD.


   METHOD num2words.

    TYPES: BEGIN OF ty_map,
             num  TYPE i,
             word TYPE string,
           END OF ty_map.

    DATA: lt_map TYPE STANDARD TABLE OF ty_map,
          ls_map TYPE ty_map.

    DATA: lv_int  TYPE i,
          lv_dec  TYPE i,
          lv_inp1 TYPE string,
          lv_inp2 TYPE string.

    DATA: lv_result TYPE string,
          lv_decres TYPE string.

    IF iv_num IS INITIAL.
      RETURN.
    ENDIF.

    lt_map = VALUE #(
      ( num = 0  word = 'Zero' )
      ( num = 1  word = 'One' )
      ( num = 2  word = 'Two' )
      ( num = 3  word = 'Three' )
      ( num = 4  word = 'Four' )
      ( num = 5  word = 'Five' )
      ( num = 6  word = 'Six' )
      ( num = 7  word = 'Seven' )
      ( num = 8  word = 'Eight' )
      ( num = 9  word = 'Nine' )
      ( num = 10 word = 'Ten' )
      ( num = 11 word = 'Eleven' )
      ( num = 12 word = 'Twelve' )
      ( num = 13 word = 'Thirteen' )
      ( num = 14 word = 'Fourteen' )
      ( num = 15 word = 'Fifteen' )
      ( num = 16 word = 'Sixteen' )
      ( num = 17 word = 'Seventeen' )
      ( num = 18 word = 'Eighteen' )
      ( num = 19 word = 'Nineteen' )
      ( num = 20 word = 'Twenty' )
      ( num = 30 word = 'Thirty' )
      ( num = 40 word = 'Forty' )
      ( num = 50 word = 'Fifty' )
      ( num = 60 word = 'Sixty' )
      ( num = 70 word = 'Seventy' )
      ( num = 80 word = 'Eighty' )
      ( num = 90 word = 'Ninety' )
    ).

    SPLIT iv_num AT '.' INTO lv_inp1 lv_inp2.
    lv_int = lv_inp1.
    IF lv_inp2 IS NOT INITIAL.
      lv_dec = lv_inp2.
    ENDIF.

    " ---- INTEGER PART ----
    IF lv_int < 20.
      READ TABLE lt_map INTO ls_map WITH KEY num = lv_int.
      lv_result = ls_map-word.

    ELSEIF lv_int < 100.
      READ TABLE lt_map INTO ls_map WITH KEY num = ( lv_int DIV 10 ) * 10.
      lv_result = ls_map-word.
      IF lv_int MOD 10 > 0.
        READ TABLE lt_map INTO ls_map WITH KEY num = lv_int MOD 10.
        lv_result = |{ lv_result } { ls_map-word }|.
      ENDIF.

    ELSEIF lv_int < 1000.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 100 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Hundred'.

      IF lv_int MOD 100 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 100 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSEIF lv_int < 100000.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 1000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Thousand'.

      IF lv_int MOD 1000 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 1000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSE.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 100000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Lakh'.

      IF lv_int MOD 100000 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 100000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.
    ENDIF.

    " ---- APPEND CURRENCY ONLY ONCE ----
    rv_words = lv_result.

    IF iv_top_call = abap_true.
      IF lv_dec > 0.
        lv_decres =
          num2words(
            iv_num      = |{ lv_dec }|
            iv_major    = iv_major
            iv_minor    = iv_minor
            iv_top_call = abap_false
          ).
        rv_words = |{ rv_words } { iv_major } and { lv_decres } { iv_minor } Only|.
      ELSE.
        rv_words = |{ rv_words } { iv_major } Only|.
      ENDIF.
    ENDIF.

    CONDENSE rv_words.
    TRANSLATE rv_words TO UPPER CASE.

ENDMETHOD.
ENDCLASS.
