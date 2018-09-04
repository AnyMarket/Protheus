#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyMarca
Tipo		: CLS = Classe
Descrição	: Classe de produtos do Anymarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 15/04/2015 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyMarca From AnyAcesso

	Data cCodigo
	Data cNome 
	Data cIdWeb
	Data aListaMarcas
	  	
	Method New() CONSTRUCTOR
	Method CriaMarca()
	Method AtuaMarca()
	Method AllMarcas()
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyProduto
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 15/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method New() Class AnyMarca
	_Super:New()
	
	::cCodigo		:= ""
	::cNome			:= "" 
	::cIdWeb		:= "" 
	::aListaMarcas:= {}
	
	Self:AllMarcas()
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: GetMarca
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 15/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method CriaMarca() Class AnyMarca	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/brands'
	Local cJSon			:= ''
	Local lAchou		:= .F.
	Local nI			:= 0
	Local cCodMarca		:= ''
	Local cDescMarca		:= ''
	
	Private oJsMarca	:= Nil //Foi declarada como privada para a função TYPE funcionar
	
	cCodMarca 	:= ::cCodigo
	cDescMarca 	:= ::cNome
	
	If AllTrim(cCodMarca) == ''
		Return 
	EndIf
       
	cRespJSON 	:= HTTPGet(cUrl,,,::aHeadStr,@cHeaderRet)
	
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		
		//Transforma a string em um Objeto JSON (Array)
		FWJsonDeserialize(cRespJSON,@oJsMarca)
		lAchou := .F.
		
		nPos := aScan(::aListaMarcas,{|x| AllTrim(Upper(x[3])) == AllTrim(Upper(::cCodigo))})
		If nPos > 0
			lAchou := .T.
			::cIdWeb := ::aListaMarcas[nPos, 1]	
		EndIf
		
		If !lAchou
			//Caso não encontre, cadastra um novo
			cJSon := '{'
	  		cJSon += '		"name":"'+AllTrim(cDescMarca)+'",'
	  		cJSon += '		"partnerId":"'+AllTrim(cCodMarca)+'"'
	  		cJSon += '}'
	  		
			cHeaderRet := '' 
			cRespJSON := HTTPPost(cUrl,,cJSon,,::aHeadStr,@cHeaderRet)
			
			If cRespJSON <> NIL 
				If "200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet .AND. !('Duplicidade de SKU' $ cRespJSON)
					FWJsonDeserialize(cRespJSON,@oJsMarca)
					
					::cIdWeb := cValToChar(oJsMarca:ID)	
					aAdd(::aListaMarcas, { cValToChar(oJsMarca:id), oJsMarca:name, oJsMarca:partnerId})
				EndIf
			EndIf
		EndIf
	EndIf
Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AllMarcas
Tipo		: Função estática
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 15/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AllMarcas() Class AnyMarca	
	Local cRespJSON	:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/brands?limit=100'
	Local nI			:= 0
	Local nCount		:= 0
	
	Private oJsMarca	:= Nil //Foi declarada como privada para a função TYPE funcionar

	::aListaMarcas 	:= {} 
	While .T.
		cHeaderRet 	:= ''
		cRespJSON 		:= HTTPGET(cUrl+'&offset='+cValToChar(nCount),,,::aHeadStr,@cHeaderRet)
       	
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			
			//Transforma a string em um Objeto JSON (Array)
			oJsMarca := Nil
			FWJsonDeserialize(cRespJSON,@oJsMarca)
	
			//Localiza a marca pelo nome da marca
			If Type('oJsMarca:Content') != 'U'
				For nI := 1 to Len(oJsMarca:Content)
					If Type('oJsMarca:Content['+cValToChar(nI)+']:partnerId')!='U' //TemPartnerID(nI) 
						aAdd(::aListaMarcas, ; 
							{ ;
								cValToChar(oJsMarca:Content[nI]:id), ;
								oJsMarca:Content[nI]:name, ;
								oJsMarca:Content[nI]:partnerId;
							})
					EndIf
				Next
			Else
				Exit
			EndIf
		Else
			Exit
		EndIf
		Self:aListaMarcas
		nCount += 100
	EndDo
Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AtuaMarca()
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AtuaMarca() Class AnyMarca	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/brands'
	Local cJSon			:= ''
	Local lAchou		:= .F.
	Local cCodMarca		:= ''
	Local cDescMarca	:= ''
	Local oPut			:= Nil 
	
	Private oJsMarca	:= Nil //Foi declarada como privada para a função TYPE funcionar
	
	cCodMarca 	:= AllTrim(::cCodigo)
	cDescMarca 	:= AllTrim(::cNome)
	::cIdWeb	:= AllTrim(::cIdWeb)
	
	If Empty(cCodMarca) .And. Empty(::cIdWeb)  
		Return
	EndIf
    
	If !Empty(::cIdWeb)
		cRespJSON 	:= HTTPGet(cUrl+'/'+::cIdWeb,,,::aHeadStr,@cHeaderRet)
		lAchou := cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
	Endif
	
	If !lAchou
		cRespJSON 	:= HTTPGet(cUrl,,,::aHeadStr,@cHeaderRet)	
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			//Transforma a string em um Objeto JSON (Array)
			FWJsonDeserialize(cRespJSON,@oJsMarca)
			lAchou := .F.
			
			nPos := aScan(::aListaMarcas,{|x| AllTrim(Upper(x[3])) == AllTrim(Upper(::cCodigo))})
			If nPos > 0
				lAchou := .T.
				::cIdWeb := ::aListaMarcas[nPos, 1]	
			EndIf
		EndIf
	EndIf
	
	If lAchou
		cJSon := '{'
  		cJSon += '		"name":"'+AllTrim(cDescMarca)+'",'
  		cJSon += '		"partnerId":"'+AllTrim(cCodMarca)+'"'
  		cJSon += '}'
  		 
		oPut 	:= FWRest():New(cUrl+'/'+::cIdWeb)
		oPut:SetPath('')		
		oPut:Put(::aHeadStr, cJSon)
		cRespJSON := oPut:GetResult()	
		
		If !('200' $ oPut:oResponseH:cStatusCode)
			aMsgErro := {}
			aAdd(aMsgErro, 'Atualização Produto')
			aAdd(aMsgErro, cUrl)
			aAdd(aMsgErro, cRespJSON)
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
		Else
			nPos := aScan(::aListaMarcas,{|x| AllTrim(Upper(x[1])) == AllTrim(Upper(::cIdWeb))})
			If nPos > 0
				::aListaMarcas[nPos, 2] := cDescMarca
				::aListaMarcas[nPos, 3] := cCodMarca	
			EndIf
		EndIf
	EndIf
	
Return lAchou