#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyCategoria
Tipo		: CLS = Classe
Descrição	: Classe de categorias do Anymarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: AnyProduto
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto
Parâmetros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: AnyCategoria
Tipo		: MTH = Metodo
Descrição	: Lista todas as categorias do AnyMarket 
Parâmetros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: AddSubCat
Tipo		: MTH = Metodo
Descrição	: Função recursiva para obter todas as subcategorias e uma categoria 
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: ExistObj
Tipo		: Função estática
Descrição	: Função para analisar se um determinado objeto existe 
Parâmetros	: Nil
Retorno		: Boolena
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function ExistObj(oObj, cTag)
	Local lVal := .F.
	Private aJson := oObj
	
	lVal := Type("aJson"+cTag) == 'A'
	
Return lVal

/*
------------------------------------------------------------------------------------------------------------
Função		: CriaCateg
Tipo		: MTH = Metodo
Descrição	: Cria as categorias no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: GravaCat
Tipo		: Função estática
Descrição	: Obtem a categoria e as suas subcategorias de um produto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: CriaProduto
Tipo		: MTH = Metodo
Descrição	: Le as categorias no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
		
		//Obs: O Json não retorna o Id da categoria Pai
		cCodPai := ''
		 	
	EndIf
	
Return lAchou

/*
------------------------------------------------------------------------------------------------------------
Função		: DeletCateg
Tipo		: MTH = Metodo
Descrição	: Cria as categorias no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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
Função		: AtuaCateg
Tipo		: MTH = Metodo
Descrição	: Altera as categorias no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
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

	Private oJsCateg	:= Nil //Foi declarada como privada para a função TYPE funcionar

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
			aAdd(aMsgErro, 'Atualização de Categoria')
			aAdd(aMsgErro, cUrl)
			aAdd(aMsgErro, cRespJSON)
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
		EndIf
	EndIf
	
Return
/*
------------------------------------------------------------------------------------------------------------
Função		: RetiraCaracEsp
Tipo		: Função estática
Descrição	: Retira os caracteres especiais para gravar no AnyMarket
Parâmetros	: cExp1 : Valor a ser tratado na função 
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function RetiraCaracEsp(_sOrig)
   local _sRet := _sOrig
   _sRet = strtran (_sRet, "á", "a")
   _sRet = strtran (_sRet, "é", "e")
   _sRet = strtran (_sRet, "í", "i")
   _sRet = strtran (_sRet, "ó", "o")
   _sRet = strtran (_sRet, "ú", "u")
   _SRET = STRTRAN (_SRET, "Á", "A")
   _SRET = STRTRAN (_SRET, "É", "E")
   _SRET = STRTRAN (_SRET, "Í", "I")
   _SRET = STRTRAN (_SRET, "Ó", "O")
   _SRET = STRTRAN (_SRET, "Ú", "U")
   _sRet = strtran (_sRet, "ã", "a")
   _sRet = strtran (_sRet, "õ", "o")
   _SRET = STRTRAN (_SRET, "Ã", "A")
   _SRET = STRTRAN (_SRET, "Õ", "O")
   _sRet = strtran (_sRet, "â", "a")
   _sRet = strtran (_sRet, "ê", "e")
   _sRet = strtran (_sRet, "î", "i")
   _sRet = strtran (_sRet, "ô", "o")
   _sRet = strtran (_sRet, "û", "u")
   _SRET = STRTRAN (_SRET, "Â", "A")
   _SRET = STRTRAN (_SRET, "Ê", "E")
   _SRET = STRTRAN (_SRET, "Î", "I")
   _SRET = STRTRAN (_SRET, "Ô", "O")
   _SRET = STRTRAN (_SRET, "Û", "U")
   _sRet = strtran (_sRet, "ç", "c")
   _sRet = strtran (_sRet, "Ç", "C")
   _sRet = strtran (_sRet, "à", "a")
   _sRet = strtran (_sRet, "À", "A")
   _sRet = strtran (_sRet, "º", ".")
   _sRet = strtran (_sRet, "ª", ".")
   _sRet = strtran (_sRet, chr (9), " ") // TAB
   
   //Problemas API
   _sRet = strtran (_sRet, "/", " ")
return _sRet
