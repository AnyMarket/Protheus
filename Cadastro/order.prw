#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
 
WSRESTFUL order DESCRIPTION "Exemplo de servi�o REST"
 
	WSDATA count      AS INTEGER
	WSDATA startIndex AS INTEGER
	 
	WSMETHOD GET DESCRIPTION "Exemplo de retorno de entidade(s)" WSSYNTAX "/order || /order/{id}"
	WSMETHOD POST DESCRIPTION "Exemplo de inclusao de entidade" WSSYNTAX "/order"
	 
END WSRESTFUL
 
//====================================================================================================
WSMETHOD GET WSRECEIVE startIndex, count WSSERVICE order
	Local i
	 
	// define o tipo de retorno do m�todo
	::SetContentType("application/json")
	 
	// verifica se recebeu parametro pela URL
	// exemplo: http://localhost:8080/order/1
	If Len(::aURLParms) > 0
	 
	  // insira aqui o c�digo para pesquisa do parametro recebido
	 
	  // exemplo de retorno de um objeto JSON
	  ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"order"}')
	 
	Else
	  	// as propriedades da classe receber�o os valores enviados por querystring
	 	// exemplo: http://localhost:8080/order?startIndex=1&count=10
		DEFAULT ::startIndex := 1, ::count := 5
	 
	  	// exemplo de retorno de uma lista de objetos JSON
	  	::SetResponse('[')
	  	For i := ::startIndex To ::count + 1
	  		If i > ::startIndex
	      		::SetResponse(',')
	    	EndIf
	    	::SetResponse('{"id":' + Str(i) + ', "name":"order"}')
	  	Next
	  	
	  	::SetResponse(']')
	  	
	EndIf
	
Return .T.

//====================================================================================================
// O metodo POST pode receber parametros por querystring, por exemplo:
WSMETHOD POST WSSERVICE order
	Local lPost := .T.
	Local cBody
	Local cRetAnalise := 'Comando executado com sucesso'
	
	// Exemplo de retorno de erro
	If Len(::aURLParms) > 0
		SetRestFault(400, "N�o � poss�vel receber parametro do metodo POST")
		lPost := .F.
	Else
	 	// recupera o body da requisi��o
	 	cBody := ::GetContent()
	 	
	 	// insira aqui o c�digo para opera��o inser��o
	 	// exemplo de retorno de um objeto JSON
	 	If U_AnalisaDados(cBody, @cRetAnalise)
	 		::SetResponse(cRetAnalise)
	 	Else
		 	SetRestFault(400, cRetAnalise)
		 	lPost := .F.
	 	Endif
	EndIf
	
Return lPost

//====================================================================================================
user Function AnalisaDados(cBody, cAnalise)
	Local lRet 		:= .T.

	lRet := U_ESTCA007(cBody)
	
	If !lRet
		cAnalise := 'Erro na integra��o'
	EndIf

Return lRet