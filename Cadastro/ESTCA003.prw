#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA003
Tipo		: Função de usuário
Descrição	: Atualiza preco de venda de todos os produtos cadastrados no AnyMarket
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA003()
	Local oProduto	:= AnyProduto():New()
	Local cAlias 	:= GetNextAlias()  
	Local nMaximo	:= 100
	
	BeginSql Alias cAlias		 		 	
	 	SELECT	
	 		SB0.B0_PRV1, Z1_IDWEB
		FROM 
			%Table:SB1% SB1
			JOIN %Table:SB0% SB0 ON SB0.B0_FILIAL = %xFilial:SB0% AND SB0.%notdel% AND SB0.B0_COD = SB1.B1_COD	 
			JOIN %Table:SZ1% SZ1 ON Z1_FILIAL = %xFilial:SZ1% AND SZ1.%NotDel% AND Z1_PRODUTO = B1_COD
		WHERE
			B1_FILIAL = %xFilial:SB1% AND SB1.%NotDel%
			AND B1_YSITE = 'S'
	EndSql	 		 		
		 	
	(cAlias)->(dbGoTop())
	While (cAlias)->(!Eof())
		aAdd(oProduto:aPrecos,{	(cAlias)->Z1_IDWEB, Round((cAlias)->B0_PRV1,2)})
		
		(cAlias)->(DbSkip())
		
		If ( Len(oProduto:aPrecos) > 0 .and. (cAlias)->(Eof()) ) .or. Len(oProduto:aPrecos) == nMaximo
			oProduto:AllAtuPreco()				
			oProduto:aPrecos := {}
		EndIf
		
	EndDo

	(cAlias)->(dbCloseArea())
	
	FreeObj(oProduto)

Return