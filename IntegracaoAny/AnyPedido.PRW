#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyPedido
Tipo		: CLS = Classe
Descrição	: Classe para Manipular os Pedidos via REST com AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyPedido From AnyAcesso
  	
	Data cStatus
	Data aPedidos
	Data cIdWeb      
	Data dDtCriacao
	Data cCodTracking
	Data cNFiscal
	Data cChaveNF
	Data cSerieNF
	Data cEmissaoNF
  	
	Method New() CONSTRUCTOR
	Method GetAllPedidos()
	Method CancPedido() 
                
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/         
Method New() Class AnyPedido

	//Inicializa Metodos New da Classe BSAcesso          
	_Super:New()
	
	::cStatus	:= ""
	::cIdWeb	:= "" 
	::aPedidos	:= {}
	
  	//Self:GetAllPedidos()
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method GetAllPedidos() Class AnyPedido
	Local cRespJSON		:= ''
	Local cHeaderRet 		:= ''
	Local cUrl				:= ::cURLBase+'/orders/feeds'
	Local nI				:= 0
	
	Private oJsPediFeed	:= Nil
	
	//====================================================================
	//Obs:
	//O Feeds so mostra os pedido alterados
	//Os Feeds só mostram 10 pedidos, portanto ao consultar os primeiros 10
	//é necessário atualizar os pedidos informando que os mesmo já foram
	//visualizados para a próxima consulta não listar os mesmo pedidos
	//====================================================================	
	::aPedidos 	:= {}
	cHeaderRet	:= ''
	cRespJSON 	:= HTTPGET(cUrl,,,::aHeadStr,@cHeaderRet)
	
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		oJsPediFeed := NiL
		FWJsonDeserialize(cRespJSON,@oJsPediFeed)
		
		If Type('oJsPediFeed') == 'A'
			For nI := 1 to Len(oJsPediFeed)
				aAdd(::aPedidos, {oJsPediFeed[nI]:id, oJsPediFeed[nI]:token})
			Next
		EndIf		
	EndIf

Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyPedido
Tipo		: CLS = Classe
Descrição	: Classe para Manipular os Pedidos via REST com AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyPedId From AnyAcesso
  	
	Data cMarketPlace
	Data cIdWeb
	Data dDataEmissao      
	Data cStatus
	Data cStatusMP
	Data nVlrFrete
	Data cMPlaceId
	Data cNome
	Data cCliMP
	Data cCliAny
	Data cDocumento
	Data cTipoDoc
	Data cMunicipio
	Data cUF  
	Data cPais
	Data cEndereco
	Data cCEP
	Data cTelefone
	Data cEmail
	Data aFormaPtgo
	Data aFormaEnvio
	Data aItems
	Data nDesconto
	Data cComplemento
	Data cBairro
	Data cNumero
	Data cUrlRastro 
	
	//Tracking
	Data cRastreio
	Data cFormaEnv
	Data cNota
	Data cSerie
	Data cChaveNFe
	Data dData
	Data cHora
	
	Data dDataEnvio
	Data cHoraEnvio
	Data dDataEntrega 
	Data cHoraEntrega
	Data dDataPrevisao
	Data cHoraPrevisao
	Data dDataTransp 
	Data cHoraTransp
  	
	Method New() CONSTRUCTOR	
	Method GetPedido()
	Method Notificar()	
	Method Concluir()
	Method Cancelar()
	Method Enviar()
	Method Faturar()	
	Method Tracking()
	Method TrocarStatus()
	Method GetPedCall()
                
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/         
Method New() Class AnyPedId

	//Inicializa Metodos New da Classe AnyAcesso   
	_Super:New()       
	
	::cMarketPlace	:= ''
	::cIdWeb		:= ''
	::dDataEmissao	:= cTod('')	
	::cStatus		:= ''
	::cStatusMP		:= ''
	::nVlrFrete		:= 0
	::cMPlaceId		:= ''
	::aFormaPtgo	:= {}
	::aFormaEnvio	:= {}
	::aItems		:= {}
	::cMunicipio 	:= ''
	::cUF			:= ''  
	::cPais			:= ''
	::cEndereco		:= ''
	::cCEP			:= ''	
	::cNome			:= ''
	::cDocumento	:= ''
	::cTelefone		:= ''
	::cEmail		:= ''
	::cCliMP		:= ''
	::cTipoDoc		:= ''
	::cCliAny		:= ''
	::nDesconto		:= 0
	::cComplemento	:= ''
	::cBairro 		:= ''
	::cNumero		:= ''
	::cRastreio		:= ''
	::cFormaEnv		:= ''
	::cNota			:= ''
	::cSerie		:= ''
	::cChaveNFe		:= ''
	::dData			:= cTod('')
	::cHora			:= ''	
	::dDataEnvio 	:= cTod('')
	::cHoraEnvio	:= ''	
	::dDataEntrega 	:= CTOD('') 
	::cHoraEntrega 	:= ''	
	::dDataPrevisao := CTOD('') 
	::cHoraPrevisao := ''	
	::dDataTransp 	:= CTOD('') 
	::cHoraTransp 	:= ''
	::cUrlRastro	:= ''
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: GetPedido
Tipo		: MTH = Metodo
Descrição	: Recupera o produto de acordo com o atributo da classe 
Parâmetros	: cExp1: IDWeb
Retorno		: Objeto
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method GetPedido(cIdWeb) Class AnyPedId
	Local cRespId			:= ''
	Local cHeaderId			:= ''
	Local cUrlId			:= ::cURLBase+'/orders/'
	Local nJ, nI			:= 0
	Local nQuantidade		:= 0
	Local nValorUnit		:= 0
	Local nTotal			:= 0
	Local nTotalBruto		:= 0
	Local oFormaPgto		:= Nil
	Local oFormaEnvio		:= Nil
	Local oItems			:= Nil
	Local lRet				:= .F.
	
	Private oJsPediFeed		:= Nil
	Private oJsPedido		:= Nil
	
	Default cIdWeb := ''
	
	cIdWeb := AllTrim(cIdWeb)
	
	If cIdWeb == '' 
		Return lRet
	EndIf
	
	::cRastreio		:= ''
	::cFormaEnv		:= ''
	::cNota			:= ''
	::cSerie		:= ''
	::cChaveNFe		:= ''
	::dData			:= cTod('')
	::cHora			:= ''
	::cIdWeb		:= ''
	
	cRespId 		:= HTTPGET(cUrlId+cIdWeb,,,::aHeadStr,@cHeaderId)
	
	If cRespId <> NIL .and. ("200 OK" $ cHeaderId .or. "201 Created" $ cHeaderId)
				
		FWJsonDeserialize(cRespId,@oJsPedido)

		If Type('oJsPedido:marketPlace') != 'U'
			::cMarketPlace	:= oJsPedido:marketPlace
		EndIf
		
		If Type('oJsPedido:marketPlaceId') != 'U'
			::cMPlaceId		:= oJsPedido:marketPlaceId
		EndIf
			
		If Type('oJsPedido:createdAt') != 'U'
			::dDataEmissao 	:= oJsPedido:createdAt
		EndIf
		
		If Type('oJsPedido:status') != 'U'
			::cStatus			:= oJsPedido:status
		EndIf
		
		If Type('oJsPedido:freight') != 'U'
			::nVlrFrete		:= oJsPedido:freight
		EndIf
						
		If Type('oJsPedido:id') != 'U'
			::cIdWeb			:= cValToChar(oJsPedido:id)
		EndIf
		
		If Type('oJsPedido:discount') != 'U'
			::nDesconto		:= oJsPedido:discount
		EndIf
		
		lRet := .T.	
		
		If Type('oJsPedido:marketPlaceShipmentStatus') != 'U'		
			::cStatusMP 	:= oJsPedido:marketPlaceShipmentStatus
		EndIf

		If Type('oJsPedido:buyer:id') != 'U'		
			::cCliAny 		:= cValToChar(oJsPedido:buyer:id)
		EndIf
		
		If Type('oJsPedido:buyer:name') != 'U'		
			::cNome 		:= oJsPedido:buyer:name
		EndIf
		
		If Type('oJsPedido:buyer:document') != 'U'		
			::cDocumento 	:= oJsPedido:buyer:document
		EndIf
		
		If Type('oJsPedido:buyer:phone') != 'U'		
			::cTelefone 	:= oJsPedido:buyer:phone
		EndIf
		
		If Type('oJsPedido:buyer:email') != 'U'		
			::cEmail 	:= oJsPedido:buyer:email
		EndIf
		
		If Type('oJsPedido:buyer:documentType') != 'U'		
			::cTipoDoc := oJsPedido:buyer:documentType
		EndIf
		
		If Type('oJsPedido:buyer:marketPlaceId') != 'U'		
			::cCliMP := oJsPedido:buyer:marketPlaceId
		EndIf
		
		If Type('oJsPedido:shipping:city') != 'U'		
			::cMunicipio 	:= oJsPedido:shipping:city
		EndIf
		
		If Type('oJsPedido:shipping:state') != 'U'
			::cUF			:= oJsPedido:shipping:state
		EndIf
	    
		If Type('oJsPedido:shipping:country') != 'U'	    
			::cPais		:= oJsPedido:shipping:country
		EndIf
		
		If Type('oJsPedido:shipping:address') != 'U'
			::cEndereco	:= oJsPedido:shipping:address
		EndIf
		
		If Type('oJsPedido:shipping:zipCode') != 'U'
			::cCEP			:= oJsPedido:shipping:zipCode
		EndIf
		
		If Type('oJsPedido:shipping:neighborhood') != 'U'
			::cBairro		:= oJsPedido:shipping:neighborhood
		EndIf
		
		If Type('oJsPedido:shipping:comment') != 'U'
			::cComplemento:= oJsPedido:shipping:comment
		EndIf
		
		If Type('oJsPedido:shipping:number') != 'U'
			::cNumero:= oJsPedido:shipping:number
		EndIf
		
		//Transportadora		
		If Type('oJsPedido:tracking:carrier') != 'U'
			::cFormaEnv:= oJsPedido:tracking:carrier
		EndIf
		
		If Type('oJsPedido:tracking:number') != 'U'
			::cRastreio:= oJsPedido:tracking:number
		EndIf
		
		If Type('oJsPedido:tracking:date') != 'U'
			::cHoraEnvio:= SubStr(oJsPedido:tracking:date, 12, 8)
			::dDataEnvio:= STOD( StrTran( SubStr( oJsPedido:tracking:date, 1, 10 ), '-', '' ))
		EndIf
		
		If Type('oJsPedido:tracking:deliveredDate') != 'U'
			::cHoraEntrega:= SubStr(oJsPedido:tracking:deliveredDate, 12, 8)
			::dDataEntrega:= STOD( StrTran( SubStr( oJsPedido:tracking:deliveredDate, 1, 10 ), '-', '' ))
		EndIf
		
		If Type('oJsPedido:tracking:estimateDate') != 'U'
			::cHoraPrevisao:= SubStr(oJsPedido:tracking:estimateDate, 12, 8)
			::dDataPrevisao:= STOD( StrTran( SubStr( oJsPedido:tracking:estimateDate, 1, 10 ), '-', '' ))
		EndIf
		
		If Type('oJsPedido:tracking:shippedDate') != 'U'
			::cHoraTransp	:= SubStr(oJsPedido:tracking:shippedDate, 12, 8)
			::dDataTransp	:= STOD( StrTran( SubStr( oJsPedido:tracking:shippedDate, 1, 10 ), '-', '' ))
		EndIf
		
		If Type('oJsPedido:tracking:url') != 'U'
			::cUrlRastro := oJsPedido:tracking:url
		EndIf
		
		//Nota fiscal
		If Type('oJsPedido:invoice:number') != 'U'
			::cNota:= oJsPedido:invoice:number
		EndIf
		If Type('oJsPedido:invoice:series') != 'U'
			::cSerie:= oJsPedido:invoice:series
		EndIf
		If Type('oJsPedido:invoice:accessKey') != 'U'
			::cChaveNFe:= oJsPedido:invoice:accessKey
		EndIf
		If Type('oJsPedido:invoice:date') != 'U' //2016-02-19T10:24:00.000Z		
			::cHora:= SubStr(oJsPedido:invoice:date, 12, 8)
			::dData:= STOD( StrTran( SubStr( oJsPedido:invoice:date, 1, 10 ), '-', '' ))
		EndIf
		
		If Type('oJsPedido:payments') == 'A'
			For nJ	:= 1 to Len(oJsPedido:payments)
				oFormaPgto		:= AnyFormaPtgo():New()
				oFormaPgto:cForma		:= ''
				oFormaPgto:cStatus	:= ''
				oFormaPgto:nValor	 	:= 0
				
				If Type('oJsPedido:payments['+cValtochar(nJ)+']:method') != 'U'
					oFormaPgto:cForma		:= oJsPedido:payments[nJ]:method
				EndIf
				
				If Type('oJsPedido:payments['+cValtochar(nJ)+']:status') != 'U'
					oFormaPgto:cStatus	:= oJsPedido:payments[nJ]:status
				EndIf
				
				If Type('oJsPedido:payments['+cValtochar(nJ)+']:value') != 'U'
					oFormaPgto:nValor		:= oJsPedido:payments[nJ]:value
				EndIf		
				aAdd(::aFormaPtgo, oFormaPgto)	
			Next
		EndIf

		If Type('oJsPedido:items') == 'A'
			For nJ := 1 to Len(oJsPedido:items)
				If Type('oJsPedido:items['+cValtochar(nJ)+']:amount') != 'U'
					nQuantidade	:= oJsPedido:items[nJ]:amount
				EndIf
				
				If Type('oJsPedido:items['+cValtochar(nJ)+']:unit') != 'U'
					nValorUnit		:= oJsPedido:items[nJ]:unit
				EndIf
				
				If Type('oJsPedido:items['+cValtochar(nJ)+']:total') != 'U'
					nTotal			:= oJsPedido:items[nJ]:total
				EndIf
				
				If Type('oJsPedido:items['+cValtochar(nJ)+']:gross') != 'U'
					nTotalBruto	:= oJsPedido:items[nJ]:gross
				EndIf

				If Type('oJsPedido:items['+cValtochar(nJ)+']:sku') != 'U' .and. Type('oJsPedido:items['+cValtochar(nJ)+']:product') != 'U'
				
					If Type('oJsPedido:items['+cValtochar(nJ)+']:sku:partnerId') != 'U'
						oItems				:= AnyItens():New()
						oItems:cProduto	:= TrataProd(oJsPedido:items[nJ]:sku:partnerId)
					Else
						Loop
					EndIf
						
					oItems:nQuantidade	:= nQuantidade
					oItems:nValorUnit	:= nValorUnit	
					oItems:nTotal		:= nTotal
					oItems:nTotalBruto	:= nTotalBruto
					
					If Type('oJsPedido:items['+cValtochar(nJ)+']:product:id') != 'U'
						oItems:cProdID		:= cValToChar(oJsPedido:items[nJ]:product:id)
					EndIf
					
					If Type('oJsPedido:items['+cValtochar(nJ)+']:product:title') != 'U'
						oItems:cTitulo		:= oJsPedido:items[nJ]:product:title
					EndIf
					
					If Type('oJsPedido:items['+cValtochar(nJ)+']:sku:id') != 'U'
						oItems:cSkuId		:= cValtochar(oJsPedido:items[nJ]:sku:id)
					EndIf
					oItems:nDesconto		:= nTotalBruto-nTotal
				
					aAdd(::aItems, oItems)

				EndIf

				If Type('oJsPedido:items['+cValtochar(nJ)+']:shippings') == 'A'
					For nI	:= 1 to Len(oJsPedido:items[nJ]:shippings)
						
						oFormaEnvio		:= AnyFormaEnvio():New()
						
						If Type('oJsPedido:items['+cValtochar(nJ)+']:shippings['+cValtochar(nI)+']:id') != 'U'
							oFormaEnvio:cId		:= cValToChar(oJsPedido:items[nJ]:shippings[nI]:id)
						EndIf		
					
						If Type('oJsPedido:items['+cValtochar(nJ)+']:shippings['+cValtochar(nI)+']:shippingtype') != 'U'
							oFormaEnvio:cTipo		:= Upper(oJsPedido:items[nJ]:shippings[nI]:shippingtype)
						EndIf

						aAdd(::aFormaEnvio, oFormaEnvio)	
					Next
				EndIf
			Next
		EndIf
	EndIf
	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Recupera o pedido no CallBack 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/05/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method GetPedCall(cJson) Class AnyPedId
	Local cRespJSON	:= ''
	Local cHeaderRet:= ''
	Local cUrl		:= ::cURLBase+'/orders'
	Local nI		:= 0
	Local lRet		:= .F.
	
	Private oJsPediCall	:= Nil
	
	Default cJson := ''
	
	::cIdWeb := ''
	
	If Empty(cJson)
		Return lRet
	EndIf
	
	FWJsonDeserialize(cJson,@oJsPediCall)
	
	If Type('oJsPediCall:content:id') != 'U'
		::cIdWeb := oJsPediCall:content:id
	Else
		Return lRet
	EndIf

	::cIdWeb := AllTrim(::cIdWeb)
	
	If ::cIdWeb == ''
		Return lRet
	EndIf
	
	lRet := ::GetPedido(::cIdWeb)

Return lRet


/*
------------------------------------------------------------------------------------------------------------
Função		: FeedAlterados
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method Notificar(cToken) Class AnyPedId
	Local cRespJSON	:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/orders/'
	Local oNotifica	:= Nil
	Local cJSon		:= ''
	Local aMsgErro	:= {}
	Local lRet			:= .F.
	
	Default cToken	:= ''
	
	::cIdWeb := AllTrim(::cIdWeb)
	cToken	:= AllTrim(cToken)
	
	If ::cIdWeb == '' .Or. cToken == ''
		Return
	EndIf

	cHeaderRet 	:= ''
	cRespJSON 	:= HTTPGET(cUrl+::cIdWeb,,,::aHeadStr,@cHeaderRet)
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		oNotifica := FWRest():New(cUrl+'feeds/'+::cIdWeb)
		oNotifica:SetPath('')
		cJSon := '{ '
    	cJSon += '"token": "'+cToken+'"'
  		cJSon += '}'

  		oNotifica:Put(::aHeadStr, cJSon)
  		cRespJSON := oNotifica:GetResult()

		If !('204' $ oNotifica:oResponseH:cStatusCode)
			aAdd(aMsgErro, 'Notificação')
			aAdd(aMsgErro, cUrl+'feeds/'+::cIdWeb)							
			aAdd(aMsgErro, cRespJSON)							
			aAdd(aMsgErro, cJSon)
			//Self:EmailErro(aMsgErro)
			
		Else
			lRet := .T.
		EndIf
	EndIf
	
	If ValType(oNotifica) == 'O'
		FreeObj(oNotifica)
	EndIf
	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: Cancelar
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method Cancelar() Class AnyPedId
	Local lRet := .F.
	
	lRet := Self:TrocarStatus('CANCELED')
	
Return lRet				

/*
------------------------------------------------------------------------------------------------------------
Função		: Concluir
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method Concluir() Class AnyPedId
	Local lRet := .F.
	
	lRet := Self:TrocarStatus('CONCLUDED')
	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: Enviar
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method Enviar() Class AnyPedId
	Local lRet := .F.
	
	lRet := Self:TrocarStatus('PAID_WAITING_DELIVERY')
	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: Faturar
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/          
Method Faturar() Class AnyPedId
	Local lRet := .F.
	
	lRet := Self:TrocarStatus('INVOICED')
	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: TrocarStatus
Tipo		: MTH = Metodo
Descrição	: Recupera todos os pedidos via rest de acordo com filtros 
Parâmetros	: Nil
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/    
Method TrocarStatus(cStatus) Class AnyPedId
	Local cRespJSON	:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/orders/'
	Local oCancelar	:= Nil
	Local cJSon		:= ''
	Local aMsgErro	:= {}
	Local lRet			:= .F.
	
	Default cStatus	:= ''
	
	::cIdWeb := AllTrim(::cIdWeb)
	cStatus:= AllTrim(cStatus)
	
	If ::cIdWeb == '' .Or. cStatus == ''
		Return lRet
	EndIf

	cHeaderRet 	:= ''
	cRespJSON 	:= HTTPGET(cUrl+::cIdWeb,,,::aHeadStr,@cHeaderRet)
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		oCancelar := FWRest():New(cUrl+'/'+::cIdWeb)
		oCancelar:SetPath('')

  		cJSon := '{'
		cJSon += '  "status": "'+cStatus+'"'
		cJSon += '}'

  		oCancelar:Put(::aHeadStr, cJSon)
		cRespJSON := oCancelar:GetResult()
		lRet := (oCancelar:oResponseH:cStatusCode == '200' .and. oCancelar:oResponseH:cReason == 'OK') 
		
		If !lRet				
			aMsgErro := {}			
			aAdd(aMsgErro, 'Troca de status')
			aAdd(aMsgErro, cUrl+::cIdWeb)
			aAdd(aMsgErro, cRespJSON)
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
		EndIf
	EndIf

Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: Tracking
Tipo		: MTH = Metodo
Descrição	: 
Parâmetros	: cExp1: Ordem
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/        
Method Tracking(cTipo) Class AnyPedId

	Local cRespJSON	:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/orders/'
	Local oTransp		:= Nil
	Local cJSon		:= ''
	Local aMsgErro	:= {}
	Local lRet			:= .F.
	Local cDataHora	:= ''
	Local cDtHrTransp	:= ''
	Local cDtHrEntrega:= ''
	Local cDtHrEnvio	:= ''
	Local cDtHrPrevisao:= ''
	
	Default cTipo := ""
	
	::cIdWeb 		:= AllTrim(::cIdWeb)
	::cRastreio	:= AllTrim(::cRastreio)
	::cFormaEnv	:= AllTrim(::cFormaEnv)
	::cNota		:= AllTrim(::cNota)
	::cSerie		:= AllTrim(::cSerie)
	::cChaveNFe	:= AllTrim(::cChaveNFe)
	::cHora		:= AllTrim(::cHora)
	
	If ::dData <> CTOD('') .And. ::cHora != ''
		cDataHora := cValToChar(Year(::dData))+'-'+cValToChar(strzero( Month(::dData), 2))+;
							'-'+cValToChar(strzero(Day(::dData), 2))+'T'+::cHora+iif(Len(AllTrim(::cHora)) == 8, '-03:00', ':00-03:00')
		cDtHrTransp:= cValToChar(Year(::dData))+'-'+cValToChar(strzero( Month(::dData), 2))+;
							'-'+cValToChar(strzero(Day(::dData), 2))+'T'+::cHora+iif(Len(AllTrim(::cHora)) == 8, '-03:00', ':00-03:00')
	EndIf
	
	If ::dDataEnvio <> CTOD('') .And. ::cHoraEnvio != ''
		cDtHrEnvio := cValToChar(Year(::dDataEnvio))+'-'+cValToChar(strzero( Month(::dDataEnvio), 2))+;
							'-'+cValToChar(strzero(Day(::dDataEnvio), 2))+'T'+::cHoraEnvio+iif(Len(AllTrim(::cHoraEnvio)) == 8, '-03:00', ':00-03:00')
	EndIf
	
	If ::dDataEntrega <> CTOD('') .And. ::cHoraEntrega != ''
		cDtHrEntrega := cValToChar(Year(::dDataEntrega))+'-'+cValToChar(strzero( Month(::dDataEntrega), 2))+;
							'-'+cValToChar(strzero(Day(::dDataEntrega), 2))+'T'+::cHoraEntrega+iif(Len(AllTrim(::cHoraEntrega)) == 8, '-03:00', ':00-03:00')
	EndIf
	
	If ::dDataPrevisao <> CTOD('') .And. ::cHoraPrevisao != ''
		cDtHrPrevisao := cValToChar(Year(::dDataPrevisao))+'-'+cValToChar(strzero( Month(::dDataPrevisao), 2))+;
							'-'+cValToChar(strzero(Day(::dDataPrevisao), 2))+'T'+::cHoraPrevisao+iif(Len(AllTrim(::cHoraPrevisao)) = 8, '-03:00', ':00-03:00')
	EndIf
	
	If ::cIdWeb == ''
		Return lRet
	EndIf

	cHeaderRet 	:= ''
	//cRespJSON 	:= HTTPGET(cUrl+::cIdWeb,,,::aHeadStr,@cHeaderRet)
	cRespJSON 	:= HTTPGET(cUrl,,,::aHeadStr,@cHeaderRet)
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		oTransp := FWRest():New(cUrl+::cIdWeb)
		oTransp:SetPath('')

		cJSon	:= '{'
		//cJSon 	+= '"status": "INVOICED"' //Nota Faturada

		If cTipo == "ENV"
			
			cJSon 	+= '	"tracking": '
			cJSon 	+= '	{'
			cJSon 	+= '	    "number": "'+::cRastreio+'"'
			cJSon 	+= ', 	    "carrier": "'+::cFormaEnv+'"'
			
			If AllTrim(cDtHrEnvio) != ''
				cJSon 	+= ',	    "date": "'+cDtHrEnvio+'"'
				cJSon 	+= ',	    "shippedDate": "'+cDtHrTransp+'"'
			Endif
		
			If AllTrim(cDtHrEntrega) != ''
				cJSon += '	,       "deliveredDate": "'+cDtHrEntrega+'"'
			EndIf
			
			If AllTrim(cDtHrPrevisao) != ''
				cJSon += '	,       "estimateDate": "'+cDtHrPrevisao+'"'
			EndIf
			
			If AllTrim(::cUrlRastro) != ''
				cJSon += '	,       "url": "'+::cUrlRastro+'"'
			EndIf

			cJSon 	+= '	}'
		
		Else
			
			//cJSon 	+= ',
			
			cJSon 	+= '	"invoice": { '
	    	cJSon 	+= '  		"accessKey": "'+::cChaveNFe+'" '
	    	cJSon 	+= ', 		"series": "'+::cSerie+'" '
	    	cJSon 	+= ', 		"number": "'+::cNota+'" '
	    	cJSon 	+= ', 		"date": "'+cDataHora+'" '
			cJSon 	+= '	}'		

		EndIf
		
		cJSon 	+= '}'
		
  		oTransp:Put(::aHeadStr, cJSon)
  		cRespJSON := oTransp:GetResult()
		lRet := (oTransp:oResponseH:cStatusCode == '200' .and. oTransp:oResponseH:cReason == 'OK') 
		
		If !lRet				
			aMsgErro := {}			
			aAdd(aMsgErro, 'Tracking')
			aAdd(aMsgErro, cUrl+::cIdWeb)							
			aAdd(aMsgErro, cRespJSON)							
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
		EndIf
	EndIf
Return lRet 

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyPedido
Tipo		: CLS = Classe
Descrição	: Classe para Manipular os Pedidos via REST com AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyFormaPtgo
  	
	Data cForma
	Data cStatus
	Data nValor
  	
	Method New() CONSTRUCTOR
                
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/         
Method New() Class AnyFormaPtgo 
	
	::cForma	:= ''
	::cStatus	:= ''
	::nValor	:= 0	

Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyItens
Tipo		: CLS = Classe
Descrição	: Classe para Manipular os Pedidos via REST com AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyItens

	Data cProduto
	Data nQuantidade
	Data nValorUnit
	Data nTotal
	Data nTotalBruto
	Data cProdID
	Data cTitulo
	Data cSkuId
	Data nDesconto

	Method New() CONSTRUCTOR

EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/         
Method New() Class AnyItens

	//Inicializa Metodos New da Classe BSAcesso   
	
	::cProduto		:= ''
	::nQuantidade	:= 0
	::nValorUnit	:= 0
	::nTotal		:= 0
	::nTotalBruto	:= 0
	::cProdID		:= ''
	::cTitulo		:= ''
	::cSkuId		:= ''
	::nDesconto	:= 0
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: TrataProd
Tipo		: Função estática
Descrição	: Formata o código do produto para não gerar erro no AnyMarket
Parâmetros	: cExp1 - Códgo de produto
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function TrataProd(cProduto)
	If AllTrim(cProduto) == ''
		Return ''
	EndIf

	cProduto := AllTrim(cProduto)
 	cProduto := Replace(cProduto,"_"," ") 	
Return cProduto

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyFormaEnvio
Tipo		: CLS = Classe
Descrição	: Classe para Manipular os tipos de pedidos do AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyFormaEnvio
  	
	Data cId
	Data cTipo
  	
	Method New() CONSTRUCTOR
                
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 20/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/         
Method New() Class AnyFormaEnvio 
	
	::cId		:= ''
	::cTipo	:= ''
	
Return Self