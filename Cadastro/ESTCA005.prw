#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA005
Tipo		: Função de usuário
Descrição	: Criação de pedidos de vendas
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 25/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA005()
	Local oAnyPedido		:= Nil
	Local oPedido			:= Nil
	Local nI				:= 0
	Local nJ				:= 0
	Local cOrderID			:= ''
	Local cToken			:= ''
	Local cStatPed			:= ''
	Local cSequence			:= ''

	oAnyPedido 	:= AnyPedido():New()
	oPedido		:= AnyPedId():New()
	
	//=========================================================================================
	//O While é necessário porque o Feed do pedido só traz os 10 primeiros itens
	//Depois de gravar o pedidos no protheus é necessário notificar a AnyMarket que estes itens 
	//já foram idos para a próxima leitura não trazer os mesmo pedidos
	//=========================================================================================	
	oAnyPedido:GetAllPedidos()
	
	If Len(oAnyPedido:aPedidos) == 0
		FreeObj(oAnyPedido)
		FreeObj(oPedido)
		Return
	EndIf
	
	For nI := 1 to Len(oAnyPedido:aPedidos)
		cOrderID 	:= Padr(Upper(cValToChar(oAnyPedido:aPedidos[nI, 1])),TamSx3("Z6_IDWEB")[1])
		
		//É necessário para fazer a notificar a AnyMarket que este pedido já foi lido
		cToken		:= oAnyPedido:aPedidos[nI, 2] 
	
		If oPedido:GetPedido(AllTrim(cOrderID ))
			cStatPed	:= AllTrim(oPedido:cStatus)				
			cSequence	:= Padr(Upper(oPedido:cMPlaceId),TamSx3("Z6_PEDMP")[1])		

			If cStatPed $ "PAID_WAITING_SHIP" //Pedido pago e aguardando envio
				If CriaPedMP(oPedido)
					If CriaCliente(oPedido)
						CriaPedido(oPedido)
					EndIf
				EndIf
						
			ElseIf cStatPed == "PENDING" //Pedido pendente
				If CriaPedMP(oPedido)
					CriaCliente(oPedido)
					CriaPedido(oPedido) //Apenas para testes
				EndIf
			ElseIf cStatPed == "CANCELED" //Pedido cancelado
				CancelaPedido(oPedido)  
			Else //AllTrim(::cStatPed) $ "PAID_WAITING_DELIVERY/CONCLUDED")
				//oPedido:Notificar(::cToken)
			EndIf
		
			oAnyPedido:Notificar(cToken)	
			//oSchedPedido:AnyPedFat() 		//INVOICED: Pedido faturado
			//oSchedPedido:AnyPedEnv() 		//PAID_WAITING_DELIVERY: Pedido enviado				
			//oSchedPedido:AnyPedConc() 	//CONCLUDED: Pedido entregue
		EndIf
	Next
	
	FreeObj(oAnyPedido)
	FreeObj(oPedido)
Return

Static Function CriaPedMP(oPedido)
	Local aArea 	:= GetArea()
	Local aAreaSZ6	:= SZ6->(GetArea())
	Default oPedido := nil
	
	If oPedido == nil
		Return .F.
	EndIf
	
	If Empty(oPedido:cIdWeb)
		Return .F.
	EndIf
	
	DbSelectArea('SZ6')
	SZ6->(DbSetOrder(1)) //IdWeb
	If !SZ6->(DbSeek(xFilial('SZ6')+oPedido:cIdWeb))
	
		RecLock('SZ6', .T.)
			SZ6->Z6_FILIAL 	:= xFilial('SZ6')	
			SZ6->Z6_IDWEB	:= oPedido:cIdWeb
			SZ6->Z6_DATAINC	:= dDataBase
			SZ6->Z6_MPLACE	:= oPedido:cMarketPlace
			SZ6->Z6_PEDMP	:= oPedido:cMPlaceId
		SZ6->(MsUnLock())
	EndIf
	
	SZ6->(RestArea(aAreaSZ6))
	RestArea(aArea)  
Return .T.


Static Function CriaCliente(oPedido)
	Local aArea 	:= GetArea()
	Local aAreaSA1	:= SA1->(GetArea())
	Local aAreaCC2	:= CC2->(GetArea())
	Local lJaCadast	:= .F.
	Local cCodMun	:= '' 
	Local aDadosSA1	:= {}
	Local lRet		:= .F.
	
	Default oPedido := nil
	
	Private lMsErroAuto := .f. 
	
	If oPedido == nil
		Return .F.
	EndIf
	
	If Empty(oPedido:cIdWeb)
		Return .F.
	EndIf
	
	DbSelectArea('SA1')
	SA1->(dbSetOrder(3))
	lJaCadast := SA1->(dbSeek(xFilial("SA1")+oPedido:cDocumento))
	
	If lJaCadast               
        If SA1->A1_MSBLQL == '1'
        	MsgAlert('Cliente já cadastrado a bloqueado')
        	Return .F.
        EndIf
    EndIf
    
	If oPedido:cTipoDoc == "CPF"
		If lJaCadast
			aAdd(aDadosSA1,{"A1_LOJA"	,SA1->A1_LOJA,Nil})		
			aAdd(aDadosSA1,{"A1_COD"	,SA1->A1_COD,Nil})
		
		Else
			aAdd(aDadosSA1,{"A1_LOJA"	,"01",Nil})
			aAdd(aDadosSA1,{"A1_COD"	,GetSx8Num("SA1","A1_COD"),Nil})
		
			ConfirmSx8()
		EndIf
	
		aAdd(aDadosSA1,{"A1_PESSOA"		,Iif(oPedido:cTipoDoc == "CPF","F","J"),Nil})

		If oPedido:cUf == SM0->M0_ESTENT
			aAdd(aDadosSA1,{"A1_TIPO",Iif(oPedido:cTipoDoc == "CPF","S","R"),Nil})
		Else
			aAdd(aDadosSA1,{"A1_TIPO",Iif(oPedido:cTipoDoc == "CPF","F","R"),Nil})
		EndIf
	
		aAdd(aDadosSA1,{"A1_NOME"		, oPedido:cNome,Nil}) 
		aAdd(aDadosSA1,{"A1_NREDUZ"		, oPedido:cNome,Nil})		
		aAdd(aDadosSA1,{"A1_END"		, oPedido:cEndereco+iif(!Empty(oPedido:cNumero), ', '+oPedido:cNumero, ''),Nil})    
		aAdd(aDadosSA1,{"A1_COMPLEM"	, oPedido:cComplemento,Nil})	
		aAdd(aDadosSA1,{"A1_BAIRRO"		, oPedido:cBairro,Nil})         
		aAdd(aDadosSA1,{"A1_CEP"		, oPedido:cCEP,Nil})
		aAdd(aDadosSA1,{"A1_DDD"		, "0"+SubStr(oPedido:cTelefone,1,2),Nil})
		aAdd(aDadosSA1,{"A1_TEL"		, SubStr(oPedido:cTelefone,2,15),Nil})
		aAdd(aDadosSA1,{"A1_CGC"		, oPedido:cDocumento,Nil})
		aAdd(aDadosSA1,{"A1_INSCR"		, "ISENTO",Nil})	
		aAdd(aDadosSA1,{"A1_EMAIL"		, oPedido:cEmail,Nil})
		aAdd(aDadosSA1,{"A1_CODPAIS"	, "01058",Nil})
	
		//Verifica o cadastro de municipios do IBGE para integração
		CC2->(dbSetorder(2))
		If CC2->(dbSeek(xFilial("CC2")+UPPER(oPedido:cMunicipio)))		
			While !CC2->(Eof()) .and. CC2->CC2_FILIAL == xFilial("CC2") .and. CC2->CC2_MUN == UPPER(oPedido:cMunicipio)			
				If CC2->CC2_EST == oPedido:cUF
					cCodMun := CC2->CC2_CODMUN
					Exit
				EndIf
								
				CC2->(dbSkip())			
			EndDo
		EndIf
	
		aAdd(aDadosSA1,{"A1_EST"		,Padr(oPedido:cUF,TamSx3("A1_EST")[1]),Nil}) 
		cCodMun := '15200'
		If !Empty(cCodMun)              
			aAdd(aDadosSA1,{"A1_COD_MUN"	,Padr(cCodMun,TamSx3("A1_COD_MUN")[1]),Nil})
		EndIf
	
		SA1->(RestArea(aAreaSA1))
		CC2->(RestArea(aAreaCC2))					
		//Gravacao do Cliente
		MSExecAuto({|a,b| MATA030(a,b)},aDadosSA1,iif(lJaCadast,4,3))

		If lMsErroAuto 
			MostraErro()
			DisarmTransaction()
			lRet := .F.
		Else
			lRetorno := .T.
		EndIf
	EndIf

	SA1->(RestArea(aAreaSA1))
	CC2->(RestArea(aAreaCC2))
	RestArea(aArea)  
	
Return lRet	

Static Function CriaPedido(oPedido)
/*
	Data nVlrFrete
	Data cCliMP
	Data cCliAny
	Data cMunicipio
	Data aFormaPtgo
	Data aFormaEnvio
	Data aItems
	
	*/
	Local aAreaSA1		:= SA1->(GetArea()) 
	Local aAreaSZ1		:= SZ1->(GetArea())
	Local aAreaSZ6		:= SZ6->(GetArea())
	Local cProduto 		:= ""
	Local nPreco   		:= 0
	Local cTES	  		:= ""
	Local aCabec   		:= {}
	Local aItens   		:= {}
	Local aAuxItens		:= {}
	Local nQtdLib  		:= 0
	Local aRecSC6  		:= {}
	Local i
	Local cLoja			:= ''
	Local cCliente		:= ''
	Local lRet			:= .F.
	
	Local nVolumes 		:= 0
	Local nPesoBrut		:= 0
	Local nPesoLiq 		:= 0
	Local cEspecie 		:= "VOLUME(S)"
	Local oItem			:= Nil
	
	Default oPedido := nil
	
	Private lMsErroAuto := .f. 
	
	If oPedido == nil
		Return .F.
	EndIf
	
	If Empty(oPedido:cIdWeb)
		Return .F.
	EndIf
	
	DbSelectArea('SZ6')
	SZ6->(DbSetorder(1))
	If SZ6->(DbSeek(xFilial('SZ6')+oPedido:cIdWeb))
		If ! Empty(SZ6->Z6_PEDIDO)
			Return
		EndIf
	EndIf
	
	DbSelectArea('SA1')
	SA1->(DbSetorder(3))
	If SA1->(DbSeek(xFilial('SA1')+oPedido:cDocumento))
		cCliente:= SA1->A1_COD
		cLoja	:= SA1->A1_LOJA
	EndIf
		
	cNumPed := GetSx8Num("SC5","C5_NUM")
	ConfirmSx8()
			   
	For i:= 1 to Len(oPedido:aItems)
		oItem := oPedido:aItems[i]
		
		If ValType(oItem) != 'O'
			Loop
		EndIf
		
		DbSelectArea('SZ1')
		SZ1->(dbSetOrder(2))	
		If SZ1->(DbSeek(xFilial('SZ1')+oItem:cSkuId))
			cProduto := SZ1->Z1_PRODUTO
	    			
			//Verifica o cadastro de produto
			SB1->(dbSetOrder(1))
			If SB1->(dbSeek(xFilial("SB1")+cProduto))
		        
				cProduto := SB1->B1_COD
	
				//Define a TES via TES Inteligente				
				cTES := '501'

   				nVolumes	+= oItem:nQuantidade
				nPesoBrut	+= SB1->B1_PESO*oItem:nQuantidade
				nPesoLiq	+= SB1->B1_PESO*oItem:nQuantidade
				
				aAuxItens := {}
				aadd(aAuxItens,{"C6_ITEM"		,StrZero(i, TamSx3("C6_ITEM")[1]),Nil})
				aadd(aAuxItens,{"C6_PRODUTO"	,cProduto,Nil})
				aadd(aAuxItens,{"C6_LOCAL"		,"01",Nil})
				aadd(aAuxItens,{"C6_TES"		,cTES,Nil})
				aadd(aAuxItens,{"C6_QTDVEN"		,oItem:nQuantidade,Nil})
				aadd(aAuxItens,{"C6_QTDLIB"		,oItem:nQuantidade,Nil})
				aadd(aAuxItens,{"C6_PRUNIT"		,oItem:nValorUnit,Nil})
				aadd(aAuxItens,{"C6_PRCVEN"		,oItem:nValorUnit,Nil})
				aadd(aAuxItens,{"C6_VALOR"		,oItem:nValorUnit*oItem:nQuantidade,Nil})
				aadd(aAuxItens,{"C6_ENTREG"		,dDataBase+10,Nil})
				aadd(aAuxItens,{"C6_VALDESC"	,oItem:nDesconto,Nil})
				aadd(aAuxItens,{"C6_DESCONT"	,0,Nil})
				
				aAdd(aItens,aAuxItens)
			EndIf
		EndIf
	Next
			
	If len(aItens) > 0

		//Monta cabeçalho do pedidos de venda
		aadd(aCabec,{"C5_TIPO" 		, "N"		,Nil})
		aadd(aCabec,{"C5_NUM"		, cNumPed	,Nil})
		aadd(aCabec,{"C5_CLIENTE"	, cCliente	,Nil})
		aadd(aCabec,{"C5_LOJACLI"	, cLoja		,Nil})
		aadd(aCabec,{"C5_LOJAENT"	, cLoja		,Nil})
		aadd(aCabec,{"C5_CONDPAG"	, '001'		,Nil})		
		aadd(aCabec,{"C5_EMISSAO"	, dDataBase	,Nil})
		aadd(aCabec,{"C5_ESPECI1"	, cEspecie	,Nil})
		aadd(aCabec,{"C5_VOLUME1"	, Round(nVolumes	,TamSx3("C5_VOLUME1")[2])	,Nil})
		aadd(aCabec,{"C5_PESOL"		, Round(nPesoLiq	,TamSx3("C5_PESOL")[2])		,Nil})
		aadd(aCabec,{"C5_PBRUTO"	, Round(nPesoBrut	,TamSx3("C5_PBRUTO")[2])	,Nil})
		aadd(aCabec,{"C5_TPFRETE"	, 'C'		,Nil})
		aadd(aCabec,{"C5_FRETE"		, oPedido:nVlrFrete	,Nil})
		aadd(aCabec,{"C5_TIPLIB"	,"1"				,Nil})

		//Gravacao do PEDIDO DE VENDA
		SA1->(RestArea(aAreaSA1)) 
		SZ1->(RestArea(aAreaSZ1))
		SZ6->(RestArea(aAreaSZ6))
		
		If Len(aItens) > 0			
			MsExecAuto({|x,y,z| MATA410(x,y,z)},aCabec,aItens,3)
		EndIf
	
		If lMsErroAuto	
			DisarmTransaction()
			MostraErro()
			lRet := .F.	 
		Else
			lRet := .T.
			DbSelectArea('SZ6')
			SZ6->(DbSetorder(1))
			If SZ6->(DbSeek(xFilial('SZ6')+oPedido:cIdWeb))
				RecLock('SZ6', .F.)
					SZ6->Z6_PEDIDO := cNumPed	
				SZ6->(MsUnLock())
			EndIf	
		EndIf  
	
	EndIf

Return lRet

Static Function CancelaPedido()

Return