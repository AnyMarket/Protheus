#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Função		: AnyImagem
Tipo		: CLS = Classe
Descrição	: Classe de produtos do Anymarket
Parâmetros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Class AnyImagem From AnyAcesso

	Data cIdWeb
	Data cIdProduto
	Data cURL
	  	
	Method New() CONSTRUCTOR
	Method CriaImagem()
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
Method New() Class AnyImagem
	_Super:New()
	
	::cIdWeb	:= ''
	::cIdProduto:= ''
	::cURL		:= ''
	
Return Self

/*
------------------------------------------------------------------------------------------------------------
Função		: AddImagem
Tipo		: MTH = Metodo
Descrição	: Adiciona as imagens no AnyMarket
Parâmetros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualizações:
- 16/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
Method CriaImagem() Class AnyImagem	
	Local cRespJSON		:= ''
	Local cHeaderRet 	:= ''
	Local cUrl			:= ::cURLBase+'/products'
	Local cJSon			:= ''
	Local cIdWeb		:= ''
	Local nContImg		:= 0
	Local oJsImagem		:= nil
	Local aImagens		:= {}
	Local nI			:= 0
	
	If AllTrim(::cIdProduto) == ''
		Return
	EndIf
		
	cRespJSON 	:= HTTPGET(cUrl+'/'+AllTrim(::cIdProduto)+'/images',,,::aHeadStr,@cHeaderRet)
	FWJsonDeserialize(cRespJSON,@oJsImagem)
		
	If ValType(oJsImagem) == 'A'
		For nI := 1 to Len(oJsImagem)
			aAdd(aImagens, AllTrim(oJsImagem[nI]:URL))
		Next
	EndIf

	If aScan(aImagens, AllTrim(::cURL)) == 0
	   	cHeaderRet	:= ''
	   	cRespJSON	:= ''
	   	
	   	cJSon:= ''
		cJSon += ' {'
		//cJSon += '  "index": '+cValToChar(nContImg)
		cJSon += ' "main": true'
		cJSon += ', "url": "'+AllTrim(::cURL)+'"'
		cJSon += ', "thumbnailUrl": "'+AllTrim(::cURL)+'"'
		cJSon += ', "lowResolutionUrl": "'+AllTrim(::cURL)+'"'
		cJSon += ', "standardUrl": "'+AllTrim(::cURL)+'"'
		//cJSon += ', "status": "PROCESSED"
		cJSon += ' }'
		       
		cRespJSON 	:= HTTPPOST(cUrl+'/'+AllTrim(::cIdProduto)+'/images',,cJSon,,::aHeadStr,@cHeaderRet)
		FWJsonDeserialize(cRespJSON,@oJsImagem)
	
		If ValType(cRespJSON) == 'C'
			If !("200 OK" $ cHeaderRet .or. "201 Created" $ cHeaderRet )
				aMsgErro := {}
				aAdd(aMsgErro, 'Cadastro de imagens')
				aAdd(aMsgErro, cJSon)
				Self:EmailErro(aMsgErro)
			Else
				::cIdWeb := oJsImagem:id
			EndIf
		EndIf
				
		If ValType(oJsImagem) == 'O'
		  	FreeObj(oJsImagem)
		EndIf
	EndIf
Return