@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Distinct Accounting Journal Dates'
define view entity ZI_ACCT_JOURNAL_DIST 
  as select from I_AccountingDocumentJournal( P_Language: $session.system_language )
{
   key AccountingDocument,
   key CompanyCode,
   key Customer,
    PostingDate
}
where Ledger = '0L'
  and FinancialAccountType = 'D'
group by 
  AccountingDocument,
  CompanyCode,
 Customer,
  PostingDate
