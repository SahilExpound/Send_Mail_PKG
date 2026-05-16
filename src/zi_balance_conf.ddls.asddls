@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for balance conf'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BALANCE_CONF 
  as select from ZI_ACCT_JOURNAL_DIST as a 
  left outer join ztb_bal_conf as b
    on  a.CompanyCode = b.companycode
    and a.Customer    = b.customer
    and a.AccountingDocument = b.accountingdocument
   {
   key a.AccountingDocument,
   key a.CompanyCode,
   key a.Customer,
   a.PostingDate,

   b.base64,
   b.m_ind,
   b.send_mail,
   b.postingdateee
}
