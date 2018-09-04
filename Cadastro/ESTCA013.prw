#INCLUDE "protheus.ch"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "rwmake.ch"
 
/*
------------------------------------------------------------------------------------------------------------
Fun��o      : ESTCA013
Tipo        : Fun��o de usu�rio
Descri��o   : Cadastro de caracteristicas dos produtos
Par�metros  : Nil
Retorno     : Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 19/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA013()
      Local oBrowse 
 
      //Instanciamento da Classe de Browse
      oBrowse := FWMBrowse():New()  
       
      oBrowse:SetAlias("SZ3")
      oBrowse:SetDescription("Cadastro de caracter�sticas dos Produtos")
      oBrowse:SetMenuDef('ESTCA013')
      oBrowse:Activate()
 
Return
 
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
Static Function MenuDef()
      Local aRotina := {}
       
      aAdd(aRotina,{'Visualizar'   ,'VIEWDEF.ESTCA013',0,2,0,NIL})
      aAdd(aRotina,{'Incluir'      ,'VIEWDEF.ESTCA013',0,3,0,NIL})
      aAdd(aRotina,{'Alterar'      ,'VIEWDEF.ESTCA013',0,4,0,NIL})
      aAdd(aRotina,{'Excluir'      ,'VIEWDEF.ESTCA013',0,5,0,NIL})
 
Return aRotina  
 
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
Static Function ViewDef()
      Local oModel      := FWLoadModel('ESTCA013')
      Local oStruSZ31   := FWFormStruct(2,'SZ3',{|cCampo| SZ3STRU(cCampo,'1')})
      Local oStruSZ32   := FWFormStruct(2,'SZ3',{|cCampo| SZ3STRU(cCampo,'2')})
      Local oView
     
      oView := FWFormView():New()
           
      oView:SetModel(oModel)
      oView:AddField('VIEW_SZ31',oStruSZ31,'SZ3MASTER') 
      oView:AddGrid('VIEW_SZ32',oStruSZ32,'SZ3DETAIL')
                                                     
      oView:CreateHorizontalBox('SUPERIOR',20)
      oView:CreateHorizontalBox('INFERIOR',80)
     
      oView:SetOwnerView('VIEW_SZ31','SUPERIOR')
      oView:SetOwnerView('VIEW_SZ32','INFERIOR')
 
Return oView
 
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
Static Function ModelDef()
      Local oStruSZ31 := FWFormStruct(1,'SZ3',{|cCampo| SZ3STRU(cCampo,'1')})
      Local oStruSZ32 := FWFormStruct(1,'SZ3',{|cCampo| SZ3STRU(cCampo,'2')})
      Local oModel
      
      oModel := MPFormModel():New('SZ3', , {|oModel|ValidaOK(oModel)} )
     
      oModel:AddFields('SZ3MASTER',,oStruSZ31)
      oModel:AddGrid('SZ3DETAIL','SZ3MASTER',oStruSZ32)
     
      oModel:SetDescription("Cadastro de caracter�sticas dos Produtos")
     
      oModel:SetRelation('SZ3DETAIL',{{'Z3_FILIAL','xFilial("SZ3")'},{"Z3_PRODUTO","Z3_PRODUTO"}},SZ3->(IndexKey(1)))
     
      oModel:SetPrimaryKey({"Z3_FILIAL","Z3_PRODUTO"})
     
      oModel:GetModel('SZ3MASTER'):SetDescription("Produto")
      oModel:GetModel('SZ3DETAIL'):SetDescription("Caracter�sticas")
 
Return oModel
 
//-------------------------------------------------------------------
//Rotina para defini��o dos campos a serem apresentados
//-------------------------------------------------------------------
Static Function SZ3STRU(cCampo,cTipo)
      Local lRet := .F.
          
      Do Case
            Case cTipo == '1' .and. AllTrim(cCampo) $ "Z3_FILIAL/Z3_PRODUTO/Z3_DESCPRD";      lRet := .t.
            Case cTipo == '2' .and. !(AllTrim(cCampo) $ "Z3_FILIAL/Z3_PRODUTO/Z3_DESCPRD");     lRet := .t.
      EndCase
 
Return(lRet)
 
/*
------------------------------------------------------------------------------------------------------------
Fun��o      : ValidaOK
Descri��o   : Valida dados antes de salvar
Par�metros  : oExp1: Objeto Model
Retorno     : L�gico
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 19/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function ValidaOK(oModel)
      Local lRet              := .T.
      Local nOperation        := oModel:GetOperation()
      Local oModelDetail      := oModel:GetModel( 'SZ3DETAIL' )
 
      If    nOperation == MODEL_OPERATION_INSERT
            If !ExistChav('SZ3', oModel:GetValue( 'SZ3MASTER', 'Z3_PRODUTO'), 1)
                  Help( ,, 'Help',, 'J� existe um registro com o mesmo produto informado, favor alterar o mesmo.', 1, 0 )
                  Return .F.
            EndIf
      EndIf
 
Return lRet