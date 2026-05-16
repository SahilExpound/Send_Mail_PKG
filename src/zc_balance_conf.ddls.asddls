@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for balance conf'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
//@UI: {
//    headerInfo: {
//        typeName: 'Balance Confirmation Letter',
//        typeNamePlural: 'Balance Confirmation Letter'
//    },
//    presentationVariant: [
//        {
//            sortOrder: [
//                {
//                    by: 'Customer',
//                    direction: #DESC
//                }
//            ]
//        }
//    ]
//}

@UI.headerInfo: {
    typeName: 'Balance Confirmation Letter',
    typeNamePlural: 'Balance Confirmation Letter'
}
@UI.presentationVariant: [{
    sortOrder: [{
        by: 'Customer',
        direction: #DESC
    }]
}]
@UI.selectionPresentationVariant: [{
    presentationVariantQualifier: 'Default'
}]

define root view entity ZC_BALANCE_CONF
provider contract transactional_query
 as projection on ZI_BALANCE_CONF
{

 @UI.facet: [{ id : 'Customer',
        purpose: #STANDARD,
        type: #IDENTIFICATION_REFERENCE,
        label: 'Out Payment',
         position: 10 }]
         
               @UI.lineItem:[{ position: 9, label: 'AccountingDocument' }]
      @UI.identification: [{ position: 9, label: 'AccountingDocument' }]
//      @UI.selectionField: [{ position: 10 }]
key  AccountingDocument,

//      @UI.lineItem:       [{ position: 10, label: 'CompanyCode' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
//      @UI.identification: [{ position: 10, label: 'CompanyCode' }]
//      @UI.selectionField: [{ position: 10 }]
//    key CompanyCode,

//
//@UI.lineItem: [
//  { position: 10, label: 'CompanyCode' },
//  { type: #FOR_ACTION, dataAction: 'ZPRINT', label: 'Generate Print', position: 11 }
//]
//key CompanyCode,

@UI.lineItem: [
  { position: 10, label: 'CompanyCode' },
  { type: #FOR_ACTION, dataAction: 'ZPRINT', label: 'Generate Print' },
  { type: #FOR_ACTION, dataAction: 'ZSENDMAIL', label: 'Send Mail' }
]
key CompanyCode,



     @UI.lineItem:       [{ position: 20, label: 'Customer' }]
      @UI.identification: [{ position: 20, label: 'Customer' }]
      @UI.selectionField: [{ position: 20 }]
    key Customer,
       

@UI.lineItem:       [{ position: 30, label: 'Date' }]
@UI.identification: [{ position: 30, label: 'Date' }]
//@UI.selectionField: [{ position: 30 }]
PostingDate ,


      
       m_ind,
       
    base64,
    postingdateee
    
   

}
