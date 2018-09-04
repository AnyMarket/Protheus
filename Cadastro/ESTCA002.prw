#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA002
Tipo		: Função de usuário
Descrição	: Atualiza estoque de todos os produtos cadastrados no AnyMarket
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA002()
	Local oProduto		:= AnyProduto():New()
	Local cAliasSB2 	:= GetNextAlias()  
	Local nMaximo		:= 100  
	
	BeginSql Alias cAliasSB2
	 	SELECT	
	 		SB2.B2_QATU-SB2.B2_RESERVA B2_QATU, Z1_IDWEB
		FROM 
			%Table:SB1% SB1
			JOIN %Table:SB2% SB2 ON B2_FILIAL = %xFilial:SB2% AND SB2.%NotDel% AND B2_COD = B1_COD AND B2_LOCAL = '01'	 
			JOIN %Table:SZ1% SZ1 ON Z1_FILIAL = %xFilial:SZ1% AND SZ1.%NotDel% AND Z1_PRODUTO = B1_COD
		WHERE
			B1_FILIAL = %xFilial:SB1% AND SB1.%NotDel%
			AND B1_YSITE = 'S'
	EndSql	 		 		
				 		 		
	(cAliasSB2)->(dbGoTop())
	While (cAliasSB2)->(!Eof())
		aAdd(oProduto:aEstoques,{(cAliasSB2)->Z1_IDWEB,(cAliasSB2)->B2_QATU})
		
		(cAliasSB2)->(DbSkip())
		
		If ( Len(oProduto:aEstoques) > 0 .and. (cAliasSB2)->(Eof()) ) .or. Len(oProduto:aEstoques) == nMaximo
			oProduto:AllAtuEstoques()				
			oProduto:aEstoques := {}
		EndIf

	EndDo

	(cAliasSB2)->(dbCloseArea())
	
	FreeObj(oProduto)

Return