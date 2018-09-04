#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA004
Tipo		: Função de usuário
Descrição	: Atualiza todos os produtos
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 17/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA004()
	Local oSku		:= Nil
	Local oCaract	:= Nil
	Local cProduto	:= ''
	
	Private oProduto:= AnyProduto():New()
	Private cAlias 	:= GetNextAlias() 
	
	BeginSql Alias cAlias		 		 	
	 	SELECT *
		FROM 
			%Table:SB1% SB1
			JOIN %Table:SB2% SB2 ON B2_FILIAL = %xFilial:SB2% AND SB2.%NOTDEL% AND B2_COD = B1_COD AND B2_LOCAL = '01'
			JOIN %Table:SZ4% SZ4 ON Z4_FILIAL = %xFilial:SZ4% AND SZ4.%NotDel% AND Z4_CODIGO = B1_YFABRIC
			JOIN %Table:SZ1% SZ1 ON Z1_FILIAL = %xFilial:SZ1% AND SZ1.%NotDel% AND SubString(Z1_PRODUTO, 1, 6) = SubString(B1_COD , 1, 6)
			LEFT JOIN %Table:SLK% SLK ON LK_FILIAL = %xFilial:SLK% AND SLK.%NOTDEL% AND LK_CODIGO = B1_COD
			LEFT JOIN %Table:ACV% ACV ON ACV_FILIAL = %xFilial:ACV% AND ACV.%NOTDEL% AND ACV_CODPRO = B1_COD
			LEFT JOIN %Table:ACU% ACU ON ACU_FILIAL = %xFilial:ACU% AND ACU.%NOTDEL% AND ACU_COD = ACV_CATEGO
			LEFT JOIN %Table:SB5% SB5 ON B5_FILIAL = %xFilial:SB5% AND SB5.%NOTDEL% AND B5_COD = B1_COD
		WHERE
			B1_FILIAL = %xFilial:SB1% AND SB1.%NotDel%
			AND B1_YSITE = 'S'
	EndSql
	
	(cAlias)->(DbGoTop())
	While !(cAlias)->(Eof())
		oProduto:cIdSku := (cAlias)->Z1_IDWEB
		If !oProduto:GetProd()
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		AnaliDados()
		AnaliMarca()
		AnaliCateg()
		AnaliCarac()
		AnaliSKUs()
		oProduto:AtuaProduto()
	
		(cAlias)->(DbSkip())
	EndDo

	(cAlias)->(DbCloseArea())
	FreeObj(oProduto)
	
	If ValType(oSku) == 'O'
		FreeObj(oSku)
	EndIf
	
	If ValType(oCaract) == 'O'
		FreeObj(oCaract)
	EndIf

Return

//=====================================
Static Function AnaliDados()
	
	Local cOrigANY	:= ''
	Local cInfor	:= ''
	Local cDescGar	:= ''
	Local nTempGar	:= 0
	Local nAltura	:= 0
	Local nLargura	:= 0
	Local nCompr	:= 0
	
	//Origem do Produto
	If (cAlias)->B1_ORIGEM $ '0/3/4/5/8/'
   		cOrigANY	:= '0' //Nacional
   	Else
   		cOrigANY	:= '1' //Importado
   	EndIf
   	
   	nAltura := Ceiling((cAlias)->B5_ALTURLC) //Altura
    nLargura:= Ceiling((cAlias)->B5_LARGLC) //Largura
    nCompr	:= Ceiling((cAlias)->B5_COMPRLC)	//Comprimento
    cInfor 	:= 'teste 1 '+chr(13)+chr(10)+'teste 2 '+chr(13)+chr(10)+'teste 3'
    
    DbSelectArea('SB0')
	DbSetorder(1)
		
	If SB0->(DbSeek(xFilial('SB0')+(cAlias)->B1_COD))
		
		//A garantia no protheus está no formato de dias e no AnyMarket esta em meses
		nTempGar 	:= SB0->B0_DIASGAR
		If nTempGar > 0
			nTempGar /= 30
			
			nTempGar := NoRound(nTempGar, 0)
			
		EndIf
		
		cDescGar := cValToChar(nTempGar)+' MESES CONTRA DEFEITO DE FABRICACAO"'
		
	Else
		nTempGar := 12 //meses
		cDescGar := '1 Ano de Garantia'
		
	EndIf
	
	oProduto:cCodigo 		:= (cAlias)->B1_COD
	oProduto:cDesc			:= (cAlias)->B1_DESC
	oProduto:nPeso			:= Ceiling((cAlias)->B1_PESBRU)
	oProduto:nLargura		:= nLargura
	oProduto:nComprimento	:= nCompr
	oProduto:nAltura		:= nAltura
	oProduto:nTempGarantia	:= nTempGar
	oProduto:cDesGarantia	:= cDescGar
	oProduto:nMarkup		:= 1
	oProduto:nTipoPreco		:= 1 //= 1 = MANUAL 2 = AUTOMÁTICO
	oProduto:cInfomacoes	:= cInfor
	oProduto:cOrigem		:= cOrigANY
	oProduto:cModelo		:= 'Teste 123'
	oProduto:cNBM			:= '29141100'

Return

//=====================================
Static Function AnaliMarca()
	Local cIdMarca 	:= ''
	Local oMarca	:= AnyMarca():New()
	Local cNome		:= (cAlias)->Z4_NOME
	Local cCodigo	:= (cAlias)->Z4_CODIGO
	
	If Empty((cAlias)->Z4_IDWEB)
		oMarca:cCodigo 	:= cCodigo 
		oMarca:cNome	:= cNome
		oMarca:CriaMarca()
		cIdMarca	:= oMarca:cIdWeb
	Else
		oMarca:cNome	:= cNome
		oMarca:cCodigo 	:= cCodigo
		oMarca:AtuakMarca()
		cIdMarca	:= oMarca:cIdWeb
	EndIf
	
	FreeObj(oMarca)
	oProduto:cIdMarca := cIdMarca
Return 

//=====================================
Static Function AnaliCateg()
	Local oCateg 	:= AnyCategoria():New()
	Local aSubCat	:= {}
	Local cId		:= ''
	Local nI		:= 0
	Local cCodPai	:= ''

	DbSElectArea('ACU')
	ACU->(DbSetOrder(1))
  
	cCodigo := (cAlias)->ACU_COD

	While .T.
		If ACU->(dbSeek(xFilial('ACU')+cCodigo))
			aAdd(aSubCat, {cCodigo, ACU->ACU_YIDWEB, ACU->ACU_DESC})
			cCodigo := ACU->ACU_CODPAI
		EndIf
		
		If Empty(cCodigo)
			Exit
		EndIf
	EndDo

	For nI := Len(aSubCat) to 1 STEP -1
		If !Empty(aSubCat[nI,2])
			If ACU->(dbSeek(xFilial('ACU')+aSubCat[nI,1]))
				//Caso já existe, a classe só retorna o IdWeb
				If !oCateg:GetCateg()
					oCateg:cCodigo := aSubCat[nI,1]
					oCateg:cNome   := aSubCat[nI,3]
					oCateg:cCodPai := cId
					oCateg:CriaCateg()
					cId := oCateg:cIdWeb
				Else
					oCateg:cCodigo := aSubCat[nI,1]
					oCateg:cNome   := aSubCat[nI,3]
					oCateg:cCodPai := cId
					oCateg:AtuaCateg()
					cId := oCateg:cIdWeb
				EndIf
				
				If ACU->(dbSeek(xFilial('ACU')+cCodigo))
					If Empty(ACU->ACU_YIDWEB)
						RecLock('ACU', .F.)
							ACU->ACU_YIDWEB := cId
						ACU->(MsUnLock())
					EndIf
				Endif 
			EndIf
		EndIf
	Next

	FreeObj(oCateg)
	oProduto:cIdCateg 	:= cId 
Return 

//===================================================================================
Static Function AnaliSKUs()
	Local oSku 		:= AnySku():New()	
	Local cProduto	:= SubStr( (cAlias)->B1_COD, 1, 6)
	Local cIdWeb	:= ''
	Local cDesc		:= ''
	Local cCodProd	:= ''
	Local cCodBarra	:= ''
	Local nEstoque	:= 0
	Local nPreco	:= 0
	Local aSkuCad	:= {}
	Local nI		:= 0
	Local nPos		:= 0

	For nI := 1 to Len(oProduto:aSKUs)
		oSku := oProduto:aSKUs[nI]
		aAdd(aSkuCad, oSku:cCodProd) 
	Next
	
	oSku 		:= AnySku():New()

	DbSelectArea('SB0')
	DbSetorder(1)

	While !(cAlias)->(Eof()) .and. SubStr( (cAlias)->B1_COD, 1, 6) == cProduto
		lAchou := .F.
		If Len(aSkuCad) > 0
			nPos := aScan(aSkuCad, AllTrim((cAlias)->B1_COD))			
			lAchou := nPos > 0
		EndIf
		
		oSku:cDesc 		:= SB1->B1_DESC
		oSku:nPreco		:= SB1->B1_PRV1
		oSku:cCodProd 	:= (cAlias)->B1_COD
		oSku:nQde		:= (cAlias)->B2_QATU-(cAlias)->B2_RESERVA
		oSku:cCodBarra 	:= (cAlias)->LK_CODBAR
		
		If SB0->(DbSeek(xFilial('SB0')+(cAlias)->B1_COD))
			If SB0->B0_PRV1 > 0
				oSku:nPreco := SB0->B0_PRV1
			EndIf 
		Endif
		
		If lAchou
			oProduto:aSKUs[nPos]:cDesc 		:= oSku:cDesc
			oProduto:aSKUs[nPos]:nPreco		:= oSku:nPreco
			oProduto:aSKUs[nPos]:cCodProd	:= oSku:cCodProd
			oProduto:aSKUs[nPos]:nQde		:= oSku:nQde
			oProduto:aSKUs[nPos]:cCodBarra	:= oSku:cCodBarra
		Else
			oProduto:AddSku(oSku)
		EndIf
		
		SB4->(DbSkip())
		
		(cAlias)->(dbSkip())
	EndDo

	FreeObj(oSku)
Return

//===================================================================================
Static Function AnaliCarac()
	Local oCaracte 	:= AnyCaracte():New()	
	Local cProduto	:= (cAlias)->B1_COD
	Local cIdWeb	:= ''
	Local cDesc		:= ''
	Local cCodProd	:= ''
	Local cCodBarra	:= ''
	Local nEstoque	:= 0
	Local nPreco	:= 0

	DbSElectArea('SZ3')
	DbSetOrder(1)
	
	If SZ3->(DbSeek(xFilial('SZ3')+cProduto))
		While !SZ3->(Eof()) .and. SZ3->Z3_PRODUTO == cProduto 
			oCaracte:cTitulo:= SZ3->Z3_TITULO
			oCaracte:cValor	:= SZ3->Z3_VALOR
			oProduto:AddCaracte(oCaracte)
			SZ3->(DbSkip())
		EndDo
	EndIf

	FreeObj(oCaracte)
Return
