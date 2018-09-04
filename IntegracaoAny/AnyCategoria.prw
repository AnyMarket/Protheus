#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AnyCategoria
Tipo		: CLS = Classe
Descri��o	: Classe de categorias do Anymarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyCategoria From AnyAcesso

	Data cCodigo
	Data cCodPai 
	Data cIdWeb
	Data cNome
	Data aAllCateg
	  	
	Method New() CONSTRUCTOR
	Method GetCateg()
	Method CriaCateg()
	Method AtuaCateg()
	Method AllCateg()
	Method AddSubCat()
EndClass             

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AnyProduto
Tipo		: MTH = Metodo
Descri��o	: Construtor do Objeto
Par�metros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method New() Class AnyCategoria          
	_Super:New()
	
	::cCodigo 	:= ''
	::cCodPai	:= '' 
	::cIdWeb	:= ''
	::cNome		:= ''
	::aAllCateg	:= {}

	//Self:AllCateg()
Return Self

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AnyCategoria
Tipo		: MTH = Metodo
Descri��o	: Lista todas as categorias do AnyMarket 
Par�metros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AllCateg() Class AnyCategoria
	Local cHeaderRet 	:= ''
	
	Local cRespJSON	:= ''
	Local cUrl		:= ::cURLBase+'/categories'
	Local nCount	:= 0
	Local nI		:= 1
	Local cIdItem	:= ''
	
	Local oJSon 	:= Nil
	Private oJsItem := Nil
	
	::aAllCateg 	:= {}
	  
	While .T.
		cRespJSON 	:= HTTPGET(cUrl+'?limit=100&offset='+cValToChar(nCount),,,::aHeadStr,@cHeaderRet)
		
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			
			FWJsonDeserialize(cRespJSON,@oJSon)
			
			If ExistObj(oJSon, ':Content')
				For nI := 1 to Len(oJSon:Content)
					cIdItem 	:= cValToChar(oJSon:Content[nI]:id)
					cName		:= oJSon:Content[nI]:Name
					aAdd(::aAllCateg, {cName, cIdItem, Self:AddSubCat(cIdItem, cName)})
				Next
			Else
				Exit
			EndIf

			nCount += 100
		EndIf
	EndDo
Return

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AddSubCat
Tipo		: MTH = Metodo
Descri��o	: Fun��o recursiva para obter todas as subcategorias e uma categoria 
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AddSubCat(cIdItem, nNivel) Class AnyCategoria
	Local aItens 	:= {}
	Local aItem 	:= {}
	Local cNome		:= ''
	Local nJ		:= 0	
	Local cHeaderRet:= ''	
	Local cRespJSON	:= ''
	Local cUrl		:= ::cURLBase+'/categories'
	Local oJSon		:= nil
	Local aJSon		:= {}
	
	default nNivel := 1
	
	If AllTrim(cIdItem) == ''
		Return {}
	EndIf

	cUrl +='/'+cIdItem
	
	cRespJSON 	:= HTTPGET(cUrl,,,::aHeadStr,@cHeaderRet)
		
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		FWJsonDeserialize(cRespJSON,@oJSon)

		If ExistObj(oJSon, ':Children')			
			aJSon := aClone(oJSon:Children)
			For nJ := 1 to Len(aJSon)
				nNivel ++
				cNome 	:= aJSon[nJ]:Name
				cIdItem:= cValToChar(aJSon[nJ]:Id)
				
				aItem := Self:AddSubCat(cIdItem, nNivel) 
				
				aAdd(aItens, {cNome, cIdItem, aItem})

			Next
		Else
			aAdd(aItens, {cNome, cIdItem})
			
		EndIf
	EndIf	

Return aItens

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: ExistObj
Tipo		: Fun��o est�tica
Descri��o	: Fun��o para analisar se um determinado objeto existe 
Par�metros	: Nil
Retorno		: Boolena
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function ExistObj(oObj, cTag)
	Local lVal := .F.
	Private aJson := oObj
	
	lVal := Type("aJson"+cTag) == 'A'
	
Return lVal

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: CriaCateg
Tipo		: MTH = Metodo
Descri��o	: Cria as categorias no AnyMarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method CriaCateg() Class AnyCategoria
	Local cCategoria	:= ''
	Local cIdParent		:= ''
	Local cDescricao	:= ''
	Local cHeaderRet	:= ''
	Local cUrl			:= ::cURLBase+'/categories'
	
	::cIdWeb 	:= ''
	
	If AllTrim(::cCodigo) == ''
		Return
	EndIf

	cRespJSON := HTTPGET(cUrl,,,::aHeadStr,@cHeaderRet)
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)		
		cCategoria	:= AllTrim(::cCodigo)
		cIdParent 	:= AllTrim(::cCodPai)
		cDescricao	:= RetiraCaracEsp(AllTrim(::cNome))

		::cIdWeb := GravaCat(cDescricao, cIdParent, ::cURLBase, ::aHeadStr)

	EndIf
Return

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: GravaCat
Tipo		: Fun��o est�tica
Descri��o	: Obtem a categoria e as suas subcategorias de um produto
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function GravaCat(cNome, cIdParent, cURLBase, aHeadStr)
	Local cJSon 		:= ''
	Local cId			:= ''
	Local oJsCat		:= Nil
	Local cHeaderRet	:= ''
	Local cUrl			:= cURLBase+'/categories'

	Default cIdParent	:= '' 
	
	If AllTrim(cIdParent) != ''
		DbSelectArea('ACU')
		DbSetOrder(1)
		If ACU->(DbSeek(xFilial('ACU')+cIdParent))
			cIdParent := AllTrim(ACU->ACU_YIDWEB)
		EndIf
	EndIf
	
	cNome := RetiraCaracEsp(AllTrim(cNome))
	
	cJSon := '{'
	cJSon += '"name": "'+cNome+'",'
	cJSon += '"calculatedPrice": true, '
	cJSon += '"priceFactor": 1 '
	
	If AllTrim(cIdParent) != ''
		cJSon += ', "parent": { '
      	cJSon += '  "id":'+cIdParent+'}
	EndIf
	
	cJSon += '}'

	cHeaderRet 	:= '' 
	cRespJSON 	:= HTTPPost(cUrl,,cJSon,,aHeadStr,@cHeaderRet)
	FWJsonDeserialize(cRespJSON,@oJsCat)
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)// .or. "existe uma categoria com o id interno especificado" $ cRespJSON
		cId := cValToChar(oJsCat:id)
	EndIf

Return cValToChar(cId)

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: CriaProduto
Tipo		: MTH = Metodo
Descri��o	: Le as categorias no AnyMarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method GetCateg(cId) Class AnyCategoria
	Local cHeaderRet:= '' 	
	Local cRespJSON	:= ''
	Local cUrl		:= ::cURLBase+'/categories'
	Local nI 		:= 0
	Local lAchou	:= .F.
	
	Private oJsCat	:= Nil
	
	::cIdWeb := ''
	
	If Empty(cId)
		Return .F.
	EndIf
	
	cRespJSON := HTTPGET(cUrl+'/'+cId,,,::aHeadStr,@cHeaderRet)
	
	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
		lAchou := .T.
		FWJsonDeserialize(cRespJSON,@oJsCat)
		
		If Type('oJsCat:id') != 'U'
			::cIdWeb 	:= cValToChar(oJsCat:ID)
		EndIf
		
		If Type('oJsCat:name') != 'U'
			::cNome 	:= oJsCat:name
		EndIf
		
		If Type('oJsCat:partnerId') != 'U'
			::cCodigo 	:= oJsCat:partnerId
		EndIf
		
		//Obs: O Json n�o retorna o Id da categoria Pai
		cCodPai := ''
		 	
	EndIf
	
Return lAchou

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: DeletCateg
Tipo		: MTH = Metodo
Descri��o	: Cria as categorias no AnyMarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
/*
Method DeletCateg() Class AnyCategoria
	Local cUrl			:= ::cURLBase+'/categories'	
	Local oDel			:= Nil
	Local lRet			:= .F.

	If AllTrim(::cIdWeb) == ''	
		Return lRet
	EndIf
	
	oDel := FWRest():New(cUrl+'/'+::cIdWeb)
	oDel:SetPath('')
	lRet := oDel:Delete(::aHeadStr)
	
Return lRet
*/
/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AtuaCateg
Tipo		: MTH = Metodo
Descri��o	: Altera as categorias no AnyMarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AtuaCateg() Class AnyCategoria
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/categories'
	Local cJSon			:= ''
	Local lAchou		:= .F.
	Local cCodCateg		:= ''
	Local cDescCateg	:= ''
	Local oPut			:= Nil 

	Private oJsCateg	:= Nil //Foi declarada como privada para a fun��o TYPE funcionar

	cCodCateg 	:= AllTrim(::cCodigo)
	cDescCateg 	:= AllTrim(::cNome)
	::cIdWeb	:= AllTrim(::cIdWeb)
	::cCodPai	:= AllTrim(::cCodPai)
	
	If Empty(::cIdWeb)  
		Return
	EndIf
    
	If !Empty(::cIdWeb)
		cRespJSON 	:= HTTPGet(cUrl+'/'+::cIdWeb,,,::aHeadStr,@cHeaderRet)
		lAchou := cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
	Endif
	
	If lAchou
  		cJSon := '{'
		cJSon += '		"name":"'+AllTrim(cDescCateg)+'"'
		cJSon += '	,	"partnerId":"'+AllTrim(cCodCateg)+'"'
		cJSon += '	,	"calculatedPrice": true '
		cJSon += '	,	"priceFactor": 1 '
	
		If AllTrim(::cCodPai) != ''
			cJSon += ', "parent": { '
	      	cJSon += '  "id":'+::cCodPai+'}
		EndIf
  		
  		cJSon += '}'
  		 
		oPut 	:= FWRest():New(cUrl+'/'+::cIdWeb)
		oPut:SetPath('')		
		oPut:Put(::aHeadStr, cJSon)
		cRespJSON := oPut:GetResult()	
		
		If !('200' $ oPut:oResponseH:cStatusCode)
			aMsgErro := {}
			aAdd(aMsgErro, 'Atualiza��o de Categoria')
			aAdd(aMsgErro, cUrl)
			aAdd(aMsgErro, cRespJSON)
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
		EndIf
	EndIf
	
Return
/*
------------------------------------------------------------------------------------------------------------
Fun��o		: RetiraCaracEsp
Tipo		: Fun��o est�tica
Descri��o	: Retira os caracteres especiais para gravar no AnyMarket
Par�metros	: cExp1 : Valor a ser tratado na fun��o 
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 10/04/2016 - Henrique - Constru��o inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function RetiraCaracEsp(_sOrig)
   local _sRet := _sOrig
   _sRet = strtran (_sRet, "�", "a")
   _sRet = strtran (_sRet, "�", "e")
   _sRet = strtran (_sRet, "�", "i")
   _sRet = strtran (_sRet, "�", "o")
   _sRet = strtran (_sRet, "�", "u")
   _SRET = STRTRAN (_SRET, "�", "A")
   _SRET = STRTRAN (_SRET, "�", "E")
   _SRET = STRTRAN (_SRET, "�", "I")
   _SRET = STRTRAN (_SRET, "�", "O")
   _SRET = STRTRAN (_SRET, "�", "U")
   _sRet = strtran (_sRet, "�", "a")
   _sRet = strtran (_sRet, "�", "o")
   _SRET = STRTRAN (_SRET, "�", "A")
   _SRET = STRTRAN (_SRET, "�", "O")
   _sRet = strtran (_sRet, "�", "a")
   _sRet = strtran (_sRet, "�", "e")
   _sRet = strtran (_sRet, "�", "i")
   _sRet = strtran (_sRet, "�", "o")
   _sRet = strtran (_sRet, "�", "u")
   _SRET = STRTRAN (_SRET, "�", "A")
   _SRET = STRTRAN (_SRET, "�", "E")
   _SRET = STRTRAN (_SRET, "�", "I")
   _SRET = STRTRAN (_SRET, "�", "O")
   _SRET = STRTRAN (_SRET, "�", "U")
   _sRet = strtran (_sRet, "�", "c")
   _sRet = strtran (_sRet, "�", "C")
   _sRet = strtran (_sRet, "�", "a")
   _sRet = strtran (_sRet, "�", "A")
   _sRet = strtran (_sRet, "�", ".")
   _sRet = strtran (_sRet, "�", ".")
   _sRet = strtran (_sRet, chr (9), " ") // TAB
   
   //Problemas API
   _sRet = strtran (_sRet, "/", " ")
return _sRet
