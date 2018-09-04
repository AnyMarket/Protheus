#INCLUDE "PROTHEUS.CH"
#Include "aarray.ch"
#Include "json.ch"

/*
------------------------------------------------------------------------------------------------------------
Fun��o		: AnyImagem
Tipo		: CLS = Classe
Descri��o	: Classe de produtos do Anymarket
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 16/04/2016 - Henrique - Constru��o inicial do fonte
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
Fun��o		: AnyProduto
Tipo		: MTH = Metodo
Descri��o	: Construtor do Objeto
Par�metros	: Nil
Retorno		: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 16/04/2016 - Henrique - Constru��o inicial do fonte
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
Fun��o		: AddImagem
Tipo		: MTH = Metodo
Descri��o	: Adiciona as imagens no AnyMarket
Par�metros	: Nil
Retorno	: Nil
------------------------------------------------------------------------------------------------------------
Atualiza��es:
- 16/04/2016 - Henrique - Constru��o inicial do fonte
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