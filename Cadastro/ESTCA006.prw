#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA006
Tipo		: Função de usuário
Descrição	: Criação de pedidos de vendas
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 07/05/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA006()
	Local cOrderID		:= ''
	Local oAnyPedido	:= AnyPedId():New()

	Private oProduto:= AnyProduto():New()
	Private cAlias 	:= GetNextAlias() 
	
	BeginSql Alias cAlias
		SELECT 
			* 
		FROM 
			%Table:SF2% SF2
			JOIN %Table:SD2% SD2 ON D2_FILIAL = %xFilial:SD2% AND SD2.%NOTDEL% AND D2_DOC = F2_DOC 
				AND D2_SERIE = F2_SERIE AND D2_CLIENTE = F2_CLIENTE AND D2_LOJA = F2_LOJA
			JOIN %Table:SA4% SA4 ON A4_FILIAL = %xFilial:SA4% AND SA4.%NOTDEL% AND A4_COD = F2_TRANSP
			JOIN %Table:SZ6% SZ6 ON Z6_FILIAL = %xFilial:SZ6% AND SZ6.%NOTDEL% AND Z6_PEDIDO = D2_PEDIDO AND Z6_DOC = ''
		WHERE 
			F2_FILIAL = %xFilial:SF2% AND SF2.%NOTDEL% AND F2_TIPO = 'N'
	EndSql
	
	(cAlias)->(DbGoTop())
	While !(cAlias)->(Eof())
		cOrderID := SZ6->Z6_cIdWeb
		oAnyPedido:GetPedido(cOrderID)
							
		oAnyPedido:cRastreio	:= AllTrim(SF2->F2_DOC) 
		oAnyPedido:cFormaEnv	:= 'Transportadora'
		oAnyPedido:cNota		:= AllTrim(SF2->F2_DOC)
		oAnyPedido:cSerie		:= AllTrim(SF2->F2_SERIE)
		oAnyPedido:dData		:= SF2->F2_EMISSAO
		oAnyPedido:cHora		:= SF2->F2_HORA
		oAnyPedido:cChaveNFe	:= SF2->F2_CHVNFE
		
		oAnyPedido:Faturar() //Troca o Status no pedido no Anymarket
		
		DbSelectArea('SZ6')
		SZ6->(DbSetOrder(1))
		If SZ6->(DbSeek(xFilial('SZ6')+cOrderID))
			RecLock('SZ6', .F.)
				SZ6->Z6_DOC		:= SF2->F2_DOC
				SZ6->Z6_SERIE	:= SF2->F2_SERIE
			SZ6->(MsUnLock('SZ6'))
		EndIf
		
		(cAlias)->(DbSkip())
	EndDo
Return