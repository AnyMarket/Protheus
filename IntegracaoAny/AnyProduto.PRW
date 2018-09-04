#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyProduto
Tipo		: CLS = Classe
Descrição	: Classe de produtos do Anymarket
Parâmetros	: Nil
Retorno		: Nilean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyProduto From AnyAcesso

	Data cCodigo 
	Data cIdWeb
	Data cIdSku

	Data cDesc
	Data nPeso
	Data nLargura
	Data nComprimento
	Data nAltura
	Data nTempGarantia
	Data cDesGarantia
	Data nMarkup
	Data nTipoPreco //= 1 = MANUAL 2 = AUTOMÁTICO
	Data cInfomacoes
	Data cOrigem
	Data aSKUs
	Data aCaracte
	Data cModelo
	Data cNBM
	
	Data cIdCateg
	Data cDescCate
	Data cIdMarca
	Data cDescMarca
	Data aEstoques
	Data aPrecos
	Data aListaProd
	  	
	Method New() CONSTRUCTOR
	Method CriaProduto()
	Method AddSku()
	Method AddCaracte()
	Method GetProd()
	Method AtuaProduto()

	Method AllProdutos()
	Method AllAtuEstoques()
	Method AllAtuPreco()

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
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method New() Class AnyProduto
	_Super:New()
	
	::cCodigo 		:= ""
	::cIdWeb		:= ""
	::cIdSku		:= ""
	
	::cDesc			:= ''
	::nPeso			:= 0
	::nLargura		:= 0
	::nComprimento	:= 0
	::nAltura		:= 0
	::nTempGarantia	:= 0
	::cDesGarantia	:= ''
	::nMarkup		:= ''
	::nTipoPreco 	:= 1 //= 1 = MANUAL 2 = AUTOMÁTICO
	::cInfomacoes	:= ''
	::cOrigem		:= ''
	::aSKUs			:= {}
	::aCaracte		:= {}
	::cModelo		:= ''
	::cNBM			:= ''
	
	//Variáveis de retorno
	::cIdCateg		:= ''
	::cDescCate		:= ''
	::cIdMarca		:= ''
	::cDescmarca	:= ''
	::aEstoques		:= {}
	::aPrecos		:= {}
	::aListaProd	:= {}
	
	//;;Self:AllProdutos()
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: CriaProduto
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method CriaProduto() Class AnyProduto	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/products'
	Local cJSon			:= ''
	Local nPos			:= 0
	Local aMsgErro 		:= {}
	Local nI			:= 0
	Local lRet			:= .F.
	Local cJsonSku		:= ''

	Private oJsProduto:= Nil
	
	::cIdWeb := ''
	
	If AllTrim(::cCodigo) == ''
		Return
	EndIf

	cProduto := AllTrim(::cCodigo)
	//cProduto := TrataProd(cProduto)
	cRespJSON := HTTPGet(cUrl,,,::aHeadStr,@cHeaderRet)

	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)

		cDescricao	:= Replace(::cDesc,"¨","''")

		cJSon := '	{ '
		cJSon += MontaJson(Self)
		
		//Categoria
		If AllTrim(::cIdCateg) <> ''		
			cJSon += ',  	"category": '
			cJSon += '  		{'
			cJSon += '    		"id": "'+AllTrim(::cIdCateg)+'" '	//Código da categoria
			cJSon += '  		} '
		EndIf
		
		//Marca
		If Valtype(::cIdMarca) == 'C'
			::cIdMarca := Val(::cIdMarca)
		EndIf
		
		If Valtype(::cIdMarca) == 'N' .AND. ::cIdMarca <> 0
			cJSon += ',  	"brand": '
			cJSon += '  		{'
			cJSon += '    		"id": "'+cValToChar(::cIdMarca)+'" '	//Código da categoria
			cJSon += '  		} '			
		EndIf

		If Len(::aSkus) > 0
			For nI := 1 to Len(::aSkus)
				If !Empty(cJsonSku)
					cJsonSku += ','
				EndIf
				
				oSku := ::aSkus[nI]
				
				If ValType(oSku) <> 'O'
					Loop
				EndIf
				
				cJsonSku += ' {'
				
				If !Empty(oSku:cCodBarra)
					cJsonSku += '	 "ean": "'+AllTrim(oSku:cCodBarra)+'",'	//Código de barras
				EndIf
				
				cJsonSku += '	   	"canEditEan": true'				//Edita o código de barras
				cJsonSku += '	, 	"partnerId": "'+AllTrim(oSku:cCodProd)+'"'	//ID do produto	
				cJsonSku += '	,	"amount": '+cValToChar(oSku:nQde) 				//Quantidade
				cJsonSku += '	,	"title": "'+AllTrim(oSku:cDesc)+'"'		//Título SKU
				cPreco := StrTran( cValToChar( Round(oSku:nPreco,2)), ',', '.')
				cJsonSku += '	, 	"price": '+cPreco				//Preço de venda
								
				cJsonSku += ' }'					
			Next

			If Len(::aSkus) > 0
				cJSon += ',	"skus": ['	
				cJSon += cJsonSku
				cJSon += '] '
			EndIf

			cJSon += '}'

			cHeaderRet := '' 
			cRespJSON := HTTPPost(cUrl,,cJSon,,::aHeadStr,@cHeaderRet)
			
			//code":"500","message":"Duplicidade de SKU
			If ValType(cRespJSON) == 'C'
				If "200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet .AND. !('Duplicidade de SKU' $ cRespJSON)
					FWJsonDeserialize(cRespJSON,@oJsProduto)
					::cIdWeb 	:= cValToChar(oJsProduto:ID)
					::cIdCateg	:= '' 
					::cDescCate := ''
					::cIdMarca 	:= ''
					::cDescmarca:= ''
					
					If Type('oJsProduto:skus') <> 'U'
						For nI := 1 to Len(oJsProduto:skus)
							If Type('oJsProduto:skus['+cValToChar(nI)+']:ID') <> 'U'
								AddIDSku(Self, oJsProduto:skus[nI])
								//::cIdSku := cValToChar(oJsProduto:skus[nI]:ID)
							EndIf
						Next
					Endif
					
					If Type('oJsProduto:category:id') <> 'U'
						::cIdCateg := cValToChar(oJsProduto:category:ID)
						::cDescCate := AllTrim(oJsProduto:category:Name)
					EndIf
					
					If Type('oJsProduto:brand:id') <> 'U'
						::cIdMarca 	:= cValToChar(oJsProduto:brand:ID)
						::cDescmarca 	:= AllTrim(oJsProduto:brand:Name)
					EndIf
					
					//aAdd(::aListaProd, {::cIdWeb, ::cIdSku, cProduto, ::cIdCateg, ::cDescCate, ::cIdMarca, ::cDescmarca })
					lRet := .T.
				Else
					aMsgErro := {}
					aAdd(aMsgErro, 'Cadastro de produto')
					aAdd(aMsgErro, cUrl)
					aAdd(aMsgErro, cRespJSON)
					aAdd(aMsgErro, cJSon)
					Self:EmailErro(aMsgErro)
					lRet := .F.
				EndIf				
			EndIf
		EndIf
	EndIf	
Return lRet

/*
------------------------------------------------------------------------------------------------------------
Função		: AddSku
Tipo		: MTH = Metodo
Descrição	: Adiciona o objeto Sku no objeto produto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AddSku(oSku) Class AnyProduto
	Local oObj 	:= AnySku():New()
	Default oSku := nil
	
	If ValType(oSku) == "O"
		oObj:cIdWeb		:= AllTrim(oSku:cIdWeb)
		oObj:cDesc 		:= AllTrim(oSku:cDesc)
		oObj:nPreco		:= oSku:nPreco
		oObj:cCodProd 	:= AllTrim(oSku:cCodProd)
		oObj:nQde		:= oSku:nQde
		oObj:cCodBarra 	:= AllTrim(oSku:cCodBarra)		

		aAdd(::aSkus, oObj)
	EndIf
Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AddCaracte
Tipo		: MTH = Metodo
Descrição	: Adiciona o objeto Sku no objeto produto
Parâmetros	: Nil
Retorno		: oExp1 : Objto de caracteristicas
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AddCaracte(oCaracteri) Class AnyProduto
	Local oObj 	:= AnyCaracte():New()
	Default oCaracteri := nil
	
	If ValType(oCaracteri) == "O"
		oObj:cTitulo 	:= AllTrim(oCaracteri:cTitulo)
		oObj:cValor		:= AllTrim(oCaracteri:cValor)

		aAdd(::aCaracte, oObj)
	EndIf
Return


//============================================================================
Static Function MontaJson(oAnyProd)
	Local cJSon 		:= ''
	Local nGarantia 	:= 0
	Local cDescricao	:= ''
	Local cInformacoes	:= ''
	Local cOrigANY		:= ''
	Local cCaracteris	:= ''
	Local cTitulo		:= ''
	Local cJsonCarac	:= ''
	Local nI			:= 0

	cDescricao 	:= AllTrim(oAnyProd:cDesc)
	cDescricao	:= Replace(cDescricao,"¨","''")
					
	cJSon += ' "priceFactor": '+cValToChar(oAnyProd:nMarkup) 	//Markup
	cJSon += ', "title": "'+cDescricao+'"'  			//Descrição do produto
	
	If oAnyProd:nTipoPreco == 2
		cJSon += ', "calculatedPrice": false'
	Else
		cJSon += ', "calculatedPrice": true'//Preço manual
	EndIf
	
	If oAnyProd:cModelo != ""
		cJSon += ', "model": "'+AllTrim(oAnyProd:cModelo)+'"'
	EndIf
	
	If oAnyProd:nTempGarantia > 0
		cJSon += ', "warrantyTime": '+cValToChar(oAnyProd:nTempGarantia)
	EndIf
	
	If !Empty(oAnyProd:cDesGarantia)
  		cJSon += ', "warrantyText": "'+RetiraCaracEsp(oAnyProd:cDesGarantia)+'"'
  	EndIf
    
    If oAnyProd:nAltura > 0
	  	cJSon += ', "height": '+cValToChar(Ceiling(oAnyProd:nAltura))			//Altura
	EndIf
	
	If oAnyProd:nAltura > 0
	  	cJSon += ', "width": '+cValToChar(Ceiling(oAnyProd:nLargura)) 			//Largura
	EndIf
	
	If oAnyProd:nComprimento > 0  	
	  	cJSon += ', "length": '+cValToChar(Ceiling(oAnyProd:nComprimento))		//Comprimento
	EndIf
      	
    If !empty(oAnyProd:cInfomacoes)
	  	cInformacoes := AllTrim(oAnyProd:cInfomacoes)
	  	cInformacoes := RetiraCaracEsp(cInformacoes)
	  	cInformacoes := TrataDescr(cInformacoes)
	    cInformacoes := '</p>'+cInformacoes+'<p>'  
	      	
	    cJSon += ', "description": "'+ cInformacoes+'"' //Especificações técnicas
	EndIf
	
	For nI := 1 to Len(oAnyProd:aCaracte)
		If !Empty(cJsonCarac)
			cJsonCarac += ', '
		EndIf
		
		oCatacte := oAnyProd:aCaracte[nI]
		cCaracteris 	:= AllTrim(oCatacte:cValor) 
  		cCaracteris 	:= RetiraCaracEsp(cCaracteris)
  		//cCaracteris 	:= TrataDescr(cCaracteris)

		cTitulo 		:= AllTrim(oCatacte:cTitulo) 
  		cTitulo 		:= RetiraCaracEsp(cTitulo)
  		//cTitulo 		:= TrataDescr(cTitulo)			

		cJsonCarac += ' { '
		cJsonCarac += '	    "name": "'+AllTrim(cTitulo)+'" '
		cJsonCarac += ',    "value": "'+AllTrim(cCaracteris)+'" '
		cJsonCarac += ' } '
	Next
	
	cJSon += ', "characteristics": ['
	cJSon += cJsonCarac 
	cJSon += ']'
   
   	cJSon += ', "weight": '+cValToChar(Ceiling(oAnyProd:nPeso))//Peso
   	
   	If !Empty(oAnyProd:cOrigem) 
		cJSon += ', "origin": {'
	   	cJSon += ' 		"id": '+oAnyProd:cOrigem	
	  	cJSon += '	}'
	EndIf
  	
  	If !Empty(oAnyProd:cNBM)
	  	cJSon += ', "nbm": {'
	   	cJSon += ' 		"id": '+oAnyProd:cNBM	
	  	cJSon += '	}'
	EndIf
	
Return cJSon

/*
------------------------------------------------------------------------------------------------------------
Função		: GetProd
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method GetProd() Class AnyProduto	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/products'
	Local cUrlSku		:= ::cURLBase+'/skus'
	Local nI, nJ		:= 0
	Local lAchou		:= .F.
	Local cProduto		:= ''
	Local oSkus			:= AnySku():New()
	Local oCaracte		:= AnyCaracte():New()
	
	//A variável é o tipo privada para o comando Type funcionar
	Private oJsProduto	:= Nil
	
	::cIdWeb := AllTrim(::cIdWeb)
	::cCodigo:= AllTrim(::cCodigo)
	::cIdSku := AllTrim(::cIdSku)
	
	If AllTrim(::cIdWeb) == '' .And. AllTrim(::ccodigo) == '' .and. AllTrim(::cIdSku) == ''
		Return
	EndIf
	
	If AllTrim(::cIdWeb) <> ''
		cRespJSON 	:= HTTPGET(cUrl+'/'+::cIdWeb,,,::aHeadStr,@cHeaderRet)
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			lAchou := .T.
		EndIf
	EndIf
	
	//Localiza o produto pelo partnerID do Sku
	If !lAchou .And. AllTrim(::cCodigo) <> ''
		cRespJSON 	:= HTTPGET(cUrl+'/?sku='+::cCodigo,,,::aHeadStr,@cHeaderRet)
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			lAchou := .T.
		EndIf
	EndIf
	
	//Localiza o produto pelo id do Sku
	If !lAchou .And. AllTrim(::cIdSku) <> ''
		cRespJSON 	:= HTTPGET(cUrlSku+'/'+::cIdSku,,,::aHeadStr,@cHeaderRet)
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			
			FWJsonDeserialize(cRespJSON,@oJsProduto)
			
			If Type("oJsProduto:PARTNERID") <> 'U'				
				cRespJSON 	:= HTTPGET(cUrl+'/?sku='+cValToChar(oJsProduto:PARTNERID),,,::aHeadStr,@cHeaderRet)
				If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
					lAchou := .T.
				EndIf
			EndIf
		EndIf
	EndIf

	If lAchou
		FWJsonDeserialize(cRespJSON,@oJsProduto)
		If Type('oJsProduto:Content') == 'U'
			lAchou := .F.
		EndIf
	EndIf
	
	If lAchou	
		For nI := 1 to Len(oJsProduto:Content)
		
			::cIdWeb := cValToChar(oJsProduto:Content[nI]:ID)
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:Brand:Id')!='U'
				::cIdMarca		:= oJsProduto:Content[nI]:Brand:Id
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:Brand:Name')!='U'
				::cDescMarca	:= oJsProduto:Content[nI]:Brand:Name
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:Category:Id')!='U'
				::cIdCateg		:= oJsProduto:Content[nI]:Category:Id
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:Category:Name')!='U'
				::cDescCate		:= oJsProduto:Content[nI]:Category:Name
			EndIf
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:title')!='U'
				::cDesc			:= oJsProduto:Content[nI]:title
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:weight')!='U'
				::nPeso			:= oJsProduto:Content[nI]:weight
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:width')!='U'
				::nLargura		:= oJsProduto:Content[nI]:width
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:length')!='U'
				::nComprimento	:= oJsProduto:Content[nI]:length
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:width')!='U'
				::nAltura		:= oJsProduto:Content[nI]:width
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:warrantyTime')!='U'
				::nTempGarantia	:= oJsProduto:Content[nI]:warrantyTime
			EndIf	
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:warrantyText')!='U'
				::cDesGarantia	:= oJsProduto:Content[nI]:warrantyText
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:priceFactor')!='U'
				::nMarkup		:= oJsProduto:Content[nI]:priceFactor
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:calculatedPrice')!='U'
				::nTipoPreco	:= iif(oJsProduto:Content[nI]:calculatedPrice, 1, 2) //= 1 = MANUAL 2 = AUTOMÁTICO
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:description')!='U'
				::cInfomacoes	:= oJsProduto:Content[nI]:description
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:origin:Id')!='U'
				::cOrigem		:= oJsProduto:Content[nI]:origin:Id
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:Model')!='U'
				::cModelo		:= oJsProduto:Content[nI]:Model
			EndIf	

			If Type('oJsProduto:Content['+cValToChar(nI)+']:nbm:id')!='U'
				::cNbm		:= oJsProduto:Content[nI]:nbm:id
			EndIf

			//cProduto := TrataProd(::cCodigo) 
			cProduto := AllTrim(::cCodigo)
			If Type('oJsProduto:Content['+cValToChar(nI)+']:skus')=='A'
				For nJ := 1 to Len(oJsProduto:Content[nI]:skus)
					If Type('oJsProduto:Content['+cValToChar(nI)+']:skus['+cValToChar(nJ)+']:partnerId')!='U'
						::cIdWeb := cValToChar(oJsProduto:Content[nI]:ID)
						oSkus:cIdWeb 	:= cValToChar(oJsProduto:Content[nI]:skus[nJ]:ID) 
						oSkus:cDesc 	:= oJsProduto:Content[nI]:skus[nJ]:title
						oSkus:cCodProd 	:= oJsProduto:Content[nI]:skus[nJ]:partnerId
						oSkus:cCodBarra := oJsProduto:Content[nI]:skus[nJ]:ean
						oSkus:nQde 		:= oJsProduto:Content[nI]:skus[nJ]:amount
						oSkus:nPreco 	:= oJsProduto:Content[nI]:skus[nJ]:price
						::AddSku(oSkus)
					EndIf
				Next
			ElseIf Type('oJsProduto:Content['+cValToChar(nI)+']:skus')!='U'
				If Type('oJsProduto:Content['+cValToChar(nI)+']:skus:partnerId')!='U'					
					::cIdWeb := cValToChar(oJsProduto:Content[nI]:ID)
					oSkus:cIdWeb 	:= cValToChar(oJsProduto:Content[nI]:skus:ID) 
					oSkus:cDesc 	:= oJsProduto:Content[nI]:skus:title
					oSkus:cCodProd 	:= oJsProduto:Content[nI]:skus:partnerId
					oSkus:cCodBarra := oJsProduto:Content[nI]:skus:ean
					oSkus:nQde 		:= oJsProduto:Content[nI]:skus:amount
					oSkus:nPreco 	:= oJsProduto:Content[nI]:skus:price
					::AddSku(oSkus)
				EndIf
			EndIf
			
			If Type('oJsProduto:Content['+cValToChar(nI)+']:characteristics')=='A'
				For nJ := 1 to Len(oJsProduto:Content[nI]:characteristics)
					If Type('oJsProduto:Content['+cValToChar(nI)+']:characteristics['+cValToChar(nJ)+']:titulo')!='U'
						oCaracte:cTitulo 	:= oJsProduto:Content[nI]:characteristics[nJ]:titulo
						oCaracte:cValor 	:= oJsProduto:Content[nI]:characteristics[nJ]:valor
						::AddCaracte(oCaracte)
					EndIf
				Next
			ElseIf Type('oJsProduto:Content['+cValToChar(nI)+']:characteristics:titulo')!='U'
				oCaracte:cTitulo 	:= oJsProduto:Content[nI]:characteristics:titulo
				oCaracte:cValor 	:= oJsProduto:Content[nI]:characteristics:valor
				::AddCaracte(oCaracte)
			EndIf
		Next	
	EndIf

Return lAchou

/*
------------------------------------------------------------------------------------------------------------
Função		: AtuaProduto
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AtuaProduto() Class AnyProduto
	Local cRespJSON		:= ''
	Local cHeaderRet	:= ''
	Local cUrl			:= ::cURLBase+'/products'
	Local cJSon			:= ''
	Local cProduto		:= ''
	Local cPrcVen		:= "0"
	Local nPos			:= 0
	Local aMsgErro 		:= {}
	Local oPut			:= Nil
	Local cProdAny		:= ''
	Local nGarantia		:= 0
	Local nContImg		:= 0
	Local oImagem		:= Nil
	Local cIdSku		:= ''
	Local cDescSku		:= ''
	Local cDescricao	:= ''
	Local cCodBar 		:= ''
	Local cCodBarCx 	:= ''
	Local nI 			:= 0
	Local cJsonAlt		:= ''
	Local cJsonInc		:= ''

	Private oJsProduto:= Nil
	
	If AllTrim(::cCodigo) == ''
		Return
	EndIf
	
	cProdAny := AllTrim(::cCodigo)

	If Empty(::cIdWeb)
		If !GetProd(AllTrim(Upper(cProdAny)))
			Return
		EndIf
	EndIf

	cUrl 		+= '/'+::cIdWeb
	cRespJSON 	:= HTTPGet(cUrl,,,::aHeadStr,@cHeaderRet)
	oPut 		:= FWRest():New(cUrl)

	If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)

		cProduto 	:= AllTrim(::cCodigo)
		nGarantia 	:= 0

		cJSon := '	{ '
		cJSon += '"id": '+::cIdWeb +', ' 	
		cJSon += MontaJson(Self)
		
		//Categoria
		If AllTrim(::cIdCateg) <> ''		
			cJSon += ',  	"category": '
			cJSon += '  		{'
			cJSon += '    		"id": "'+AllTrim(::cIdCateg)+'" '	//Código da categoria
			cJSon += '  		} '
		EndIf
		
		//Marca
		If Valtype(::cIdMarca) == 'C'
			::cIdMarca := Val(::cIdMarca)
		EndIf
		
		If Valtype(::cIdMarca) == 'N' .AND. ::cIdMarca <> 0
			If ::cIdMarca > 0		
				cJSon += ',  	"brand": '
				cJSon += '  		{'
				cJSon += '    		"id": "'+cValToChar(::cIdMarca)+'" '	//Código da categoria
				cJSon += '  		} '
			EndIf
		EndIf
		
		cJSon += ' } '		
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
		EndIf
		
		FreeObj(oPut)
				
		//AtualiSKU
		cRespJSON := HTTPGet(cUrl+'/skus',,,::aHeadStr,@cHeaderRet)
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			FWJsonDeserialize(cRespJSON,@oJsProduto)			
		
			If Type('oJsProduto') !='U' .AND. Len(::aSkus) > 0
				For nI := 1 to Len(::aSkus)
					cDescricao	:= Replace(cDescricao,"¨","''")
			
					oSku := ::aSkus[nI]
					
					If ValType(oSku) <> 'O'
						Loop
					EndIf
					
					If !Empty(oSku:cIdWeb)
						cJsonAlt := ''
				
						cJsonAlt += ' {'
				
						If !Empty(oSku:cCodBarra)
							cJsonAlt += '	 "ean": "'+AllTrim(oSku:cCodBarra)+'",'	//Código de barras
						EndIf
						
						cJsonAlt += '	   	"canEditEan": true'				//Edita o código de barras
						cJsonAlt += '	, 	"partnerId": "'+AllTrim(oSku:cCodProd)+'"'	//ID do produto	
						cJsonAlt += '	,	"amount": '+cValToChar(oSku:nQde) 				//Quantidade
						cJsonAlt += '	,	"title": "'+AllTrim(oSku:cDesc)+'"'		//Título SKU
						cPreco := StrTran( cValToChar( Round(oSku:nPreco,2)), ',', '.')
						cJsonAlt += '	, 	"price": '+cPreco				//Preço de venda
										
						cJsonAlt += ' }'
						
						oPut := FWRest():New(cUrl+'/skus/'+oSku:cIdWeb)
					
						oPut:SetPath('')		
						oPut:Put(::aHeadStr, cJsonAlt)
						cRespJSON := oPut:GetResult()	
						
						If !('200' $ oPut:oResponseH:cStatusCode)
							aMsgErro := {}
							aAdd(aMsgErro, 'Atualização do SKU na Atualização do Produto')
							aAdd(aMsgErro, cUrl)
							aAdd(aMsgErro, cRespJSON)
							aAdd(aMsgErro, cJsonAlt)
							Self:EmailErro(aMsgErro)
						EndIf
						
						FreeObj(oPut)
					Else
				
						cJsonInc := ' {'
				
						If !Empty(oSku:cCodBarra)
							cJsonInc += '	 "ean": "'+AllTrim(oSku:cCodBarra)+'",'	//Código de barras
						EndIf
						
						cJsonInc += '	   	"canEditEan": true'				//Edita o código de barras
						cJsonInc += '	, 	"partnerId": "'+AllTrim(oSku:cCodProd)+'"'	//ID do produto	
						cJsonInc += '	,	"amount": '+cValToChar(oSku:nQde) 				//Quantidade
						cJsonInc += '	,	"title": "'+AllTrim(oSku:cDesc)+'"'		//Título SKU
						cPreco := StrTran( cValToChar( Round(oSku:nPreco,2)), ',', '.')
						cJsonInc += '	, 	"price": '+cPreco				//Preço de venda
										
						cJsonInc += ' }'	
						
						cRespJSON := HTTPPost(cUrl+'/skus',,cJsonInc,,::aHeadStr,@cHeaderRet)
						
						If !('200' $ cHeaderRet)
							aMsgErro := {}
							aAdd(aMsgErro, 'Inserção de SKU na Atualização do Produto')
							aAdd(aMsgErro, cUrl)
							aAdd(aMsgErro, cRespJSON)
							aAdd(aMsgErro, cJsonAlt)
							Self:EmailErro(aMsgErro)
						EndIf
						
					EndIf					
				Next
				
			EndIf
		EndIf
	EndIf
				
Return	

/*
------------------------------------------------------------------------------------------------------------
Função		: AllProdutos
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AllProdutos() Class AnyProduto	
	Local cRespJSON	:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/products?limit=100'
	Local nI, nJ		:= 0
	Local nCount		:= 0
	
	//A variável é o tipo privada para o comando Type funcionar
	Private oJsProduto	:= Nil

	::aListaProd 	:= {}
	While .T.
		//cTimeIni := Time()
		cHeaderRet 	:= ''
		cRespJSON 	:= HTTPGET(cUrl+'&offset='+cValToChar(nCount),,,::aHeadStr,@cHeaderRet)
		
		If cRespJSON <> NIL .and. ("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet)
			oJsProduto := NiL
			FWJsonDeserialize(cRespJSON,@oJsProduto)			
			
			//Localiza o produto pelo código do SKU
			If Type('oJsProduto:Content') !='U'
				For nI := 1 to Len(oJsProduto:Content)
					If Type('oJsProduto:Content['+cValToChar(nI)+']:skus')!='U'
						For nJ := 1 to Len(oJsProduto:Content[nI]:skus)
							If Type('oJsProduto:Content['+cValToChar(nI)+']:skus['+cValToChar(nJ)+']:partnerId')!='U' 	
								aAdd(::aListaProd, {cValToChar(oJsProduto:Content[nI]:ID);
													, cValToChar(oJsProduto:Content[nI]:skus[nJ]:ID);
													, oJsProduto:Content[nI]:skus[nJ]:partnerId ;	
													, iif(Type('oJsProduto:Content['+cValToChar(nI)+']:category:Id')!='U',; 
														oJsProduto:Content[nI]:category:Id, 0);	
													, iif(Type('oJsProduto:Content['+cValToChar(nI)+']:brand:Id')!='U',; 
														oJsProduto:Content[nI]:brand:Id, 0)})
							EndIf
						Next
					EndIf
				Next
			Else
				Exit
			EndIf
		Else
			Exit
		EndIf

	nCount += 100
	EndDo
Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AllAtuEstoques
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 04/12/2015 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AllAtuEstoques() Class AnyProduto	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/stocks'
	Local nI		 	:= 0
	Local cJSon			:= ''
	Local aMsgErro		:= {}
	Local cProduto 		:= ''
	Local lAdicionou	:= .F.
	Local oPut			:= Nil
	
	oPut := FWRest():New(cUrl)

	If Len(::aListaProd) == 0
		Self:AllProdutos()
	EndIf
	
	cJSon := '  ['
	For nI := 1 to Len(::aEstoques)
		::cIdSku	:= ::aEstoques[nI, 1]
		
		nPos := aScan(::aListaProd, {|x|AllTrim(x[2]) = AllTrim(::cIdSku)})
		If nPos == 0
			Loop
		EndIf
		
		If lAdicionou
			cJSon += ', '
		EndIf
		
		::cCodigo  	:= ::aListaProd[nPos, 1] 
		::cIdWeb	:= ::aListaProd[nPos, 3]
		
		cJSon += '    {'
		cJSon += '      "id": '+::cIdSku+','		
		cJSon += '      "quantity": '+cValToChar(::aEstoques[nI,2])
		cJSon += '    }'
		lAdicionou := .T.
		
	Next
	
	cJSon += '  ]'

	If Len(::aEstoques) > 0

		oPut:SetPath('')
		
		oPut:Put(::aHeadStr, cJSon)
		cRespJSON := oPut:GetResult()	
		
		If !('204' $ oPut:oResponseH:cStatusCode)
			aMsgErro := {}
			aAdd(aMsgErro, 'Estoque')
			aAdd(aMsgErro, cUrl)
			aAdd(aMsgErro, cRespJSON)
			aAdd(aMsgErro, cJSon)
			Self:EmailErro(aMsgErro)
			
		EndIf
	EndIf		
Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AllAtuPreco
Tipo		: MTH = Metodo
Descrição	: Cria os produtos no AnyMarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method AllAtuPreco() Class AnyProduto	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/stocks'
	Local nI		 	:= 0
	Local cJSon			:= ''
	Local aMsgErro		:= {}
	Local cProduto 		:= ''
	Local oPut			:= Nil
	Local lEntrou		:= .F.
	
	If Len(::aListaProd) == 0
		Self:AllProdutos()
	EndIf
	
	oPut := FWRest():New(cUrl)
	
	If Len(::aPrecos) == 0
		Return
	EndIf

	cJSon := '  ['+CHR(13)+CHR(10)
	For nI := 1 to Len(::aPrecos)
		::cIdSku := AllTrim(::aPrecos[nI, 1])
		//cProduto := TrataProd(cProduto)
		
		nPos := aScan(::aListaProd, {|x|AllTrim(x[2]) == ::cIdSku})
		If nPos == 0
			Loop
		EndIf

		::cIdWeb	:= ::aListaProd[nPos, 1]
		::cCodigo 	:= ::aListaProd[nPos, 3]

		If lEntrou
			cJSon += ', '
		EndIf

		cJSon += '    {'
		cJSon += '      "id": '+::cIdSku+','		
		cJSon += '      "cost": '+cValToChar(::aPrecos[nI,2])
		cJSon += '    }'+CHR(13)+CHR(10)
		lEntrou := .T.

	Next

	cJSon += '  ]'	
	oPut:SetPath('')

	oPut:Put(::aHeadStr, cJSon)
	cRespJSON := oPut:GetResult()	

	If !('204' $ oPut:oResponseH:cStatusCode)				
		aMsgErro := {}
		aAdd(aMsgErro, 'Estoque')
		aAdd(aMsgErro, cUrl)
		aAdd(aMsgErro, cRespJSON)
		aAdd(aMsgErro, cJSon)
		Self:EmailErro(aMsgErro)		
	EndIf

Return

/*
------------------------------------------------------------------------------------------------------------
Função		: TrataProd
Tipo		: Função estática
Descrição	: Formata o código do produto para não gerar erro no AnyMarket
Parâmetros	: cExp1 - Códgo de produto
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
/*
Static Function TrataProd(cProduto)
	If AllTrim(cProduto) == ''
		Return ''
	EndIf

	cProduto := AllTrim(cProduto)
 	cProduto := Replace(cProduto," ","_")
 	cProduto := Replace(cProduto,"+","_")
 	cProduto := Replace(cProduto,".","X")
 	cProduto := Replace(cProduto,"-","Z")
 	cProduto := Replace(cProduto,"/","W")
 	
Return cProduto
*/
/*
------------------------------------------------------------------------------------------------------------
Função		: TrataDescr
Tipo		: Função estática
Descrição	: Formata o código do produto para não gerar erro no AnyMarket
Parâmetros	: cExp1 - Códgo de produto
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function TrataDescr(cTexto)
	Default cTexto := ''
	
	If AllTrim(cTexto) == ''
		Return cTexto
	EndIf

	cTexto := Replace(cTexto, chr(13)+chr(10), '</p><p>')
	cTexto := Replace(cTexto, chr(10)+chr(13), '</p><p>')
	cTexto := Replace(cTexto, '"', '&#34;')
	
Return cTexto

/*
------------------------------------------------------------------------------------------------------------
Função		: RetiraCaracEsp
Tipo		: Função estática
Descrição	: Formata o código do produto para não gerar erro no AnyMarket
Parâmetros	: cExp1 - Códgo de produto
Retorno		: String
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
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
   _sRet = strtran (_sRet, '¡', "i")
   _sRet = strtran (_sRet, '¨', "''")    // polegadas
   _sRet = strtran (_sRet, '"', "")
   
return _sRet

/*
------------------------------------------------------------------------------------------------------------
Função		: AddIDSku
Tipo		: Função estática
Descrição	: Adiciona o ID do Sku no objeto
Parâmetros	: oExp1 - Objeto Produto
			  oExp2 - Objeto Sku
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 19/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function AddIDSku(oAnyProduto, oAnySku)
	Local nI := 0
	Local oSkuArray := nil
	
	Default oSku := nil
	
	If Len(oAnyProduto:aSKUs) == 0
		Return
	EndIf
	
	If oAnySku == nil
		Return
	EndIf

	For nI := 1 to Len(oAnyProduto:aSKUs)
		oSku := oAnyProduto:aSKUs[nI]
		
		If oSku:cCodProd == oAnySku:PartnerId
			oSku:cIdWeb := cValToChar(oAnySku:Id) 
			Exit
		EndIf
	Next

Return

/*
------------------------------------------------------------------------------------------------------------
Função		: AnySku
Tipo		: CLS = Classe
Descrição	: Classe de Skus do produto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnySku From AnyAcesso
	//SKU
	Data cIdWeb
	Data cDesc
	Data cCodProd
	Data cCodBarra
	Data nQde
	Data nPreco
	  	
	Method New() CONSTRUCTOR
	Method Adiciona()
	Method GetSku()
	Method CriaSku()
	Method AtualiSku()

EndClass

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto AnySku
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method New() Class AnySku
	_Super:New()
	
	::cIdWeb	:= ''
	::cDesc		:= ''
	::cCodProd	:= ''
	::cCodBarra	:= ''
	::nQde		:= 0
	::nPreco	:= 0
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: Adiciona
Tipo		: MTH = Metodo
Descrição	: Adiciona nova caracteristica ao produto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method Adiciona() Class AnySku
	If !AnaliCBarra(::cCodBarra)
		::cCodBarra := ''
	EndIf
	
	If ::nQde < 0
		::nQde := 0
	EndIf
	
	::aSKUs(Self)
	
Return 

/*
------------------------------------------------------------------------------------------------------------
Função		: AnaliCBarra
Tipo		: Função estática
Descrição	: Analisa se o código de barras é válido, caso não seja, não cadastra no SKU
Parâmetros	: cExp1 : Código de barras
Retorno		: Boolean
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Static Function AnaliCBarra(cCodBar)
	Local cCodBarCx	:= ''
	
	Default cCodBar := ''
	
	If Empty(cCodBar)
		Return .F.
	EndIf
	 
	If Len(AllTrim(cCodBar)) == 13
		nDig := EANDIGITO(cCodBar) 
	 	
		If nDig == SubStr(cCodBar, 13, 1)
			Return .T.			
		EndIf
	EndIf

Return .F.

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyCaracte
Tipo		: CLS = Classe
Descrição	: Classe de características do produto no Anymarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyCaracte From AnyAcesso
	//Data cIdWeb	
	Data cTitulo
	Data cValor
	  	
	Method New() CONSTRUCTOR
	Method Adiciona()

EndClass

/*
------------------------------------------------------------------------------------------------------------
Função		: New
Tipo		: MTH = Metodo
Descrição	: Construtor do Objeto AnyCaracte
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method New() Class AnyCaracte
	_Super:New()
	
	::cTitulo	:= '' 
	::cValor	:= ''
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: Adiciona
Tipo		: MTH = Metodo
Descrição	: Adiciona nova caracteristica ao produto
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method Adiciona() Class AnyCaracte
	::aCaracte(Self)
	
Return