#INCLUDE "PROTHEUS.CH"

/*
------------------------------------------------------------------------------------------------------------
Função		: ESTCA001
Tipo		: Função de usuário
Descrição	: Cria as categorias no AnyMarket
Parâmetros	: 
Retorno		: 
------------------------------------------------------------------------------------------------------------
Atualizações:
- 10/04/2016 - Henrique - Construção inicial do fonte
------------------------------------------------------------------------------------------------------------
*/
User Function ESTCA001()
	Local cIdMarca	:= ''
	Local cIdCateg	:= ''
	Local cIdProduto:= ''
	Local cProduto	:= ''
	Local cProdCmp	:= ''
	
	Private cAlias 	:= GetNextAlias()

	BeginSql Alias cAlias
		SELECT *
		FROM
			%Table:SB1% SB1
			JOIN %Table:SB2% SB2 ON B2_FILIAL = %xFilial:SB2% AND SB2.%NOTDEL% AND B2_COD = B1_COD AND B2_LOCAL = '01'
			JOIN %Table:SZ4% SZ4 ON Z4_FILIAL = %xFilial:SZ4% AND SZ4.%NOTDEL% AND Z4_CODIGO = B1_YFABRIC
			JOIN %Table:SLK% SLK ON LK_FILIAL = %xFilial:SLK% AND SLK.%NOTDEL% AND LK_CODIGO = B1_COD
			JOIN %Table:ACV% ACV ON ACV_FILIAL = %xFilial:ACV% AND ACV.%NOTDEL% AND ACV_CODPRO = B1_COD
			JOIN %Table:ACU% ACU ON ACU_FILIAL = %xFilial:ACU% AND ACU.%NOTDEL% AND ACU_COD = ACV_CATEGO
			JOIN %Table:SB5% SB5 ON B5_FILIAL = %xFilial:SB5% AND SB5.%NOTDEL% AND B5_COD = B1_COD
		WHERE 
			B1_FILIAL = %xFilial:SB1% AND SB1.%NOTDEL% 
			AND B1_YSITE = 'S'
			AND NOT EXISTS(SELECT * FROM %Table:SZ1% SZ1 WHERE Z1_FILIAL = %xFilial:SZ1% AND SZ1.%NOTDEL% AND Z1_PRODUTO = SB1.B1_COD)
		ORDER BY
			B1_COD
	EndSql
	
	(cAlias)->(DbGoTop())
	
	cProduto := ''
	While !(cAlias)->(Eof())
		If cProduto == SubStr((cAlias)->B1_COD, 1, 6)
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		cProdCmp := (cAlias)->B1_COD
		cProduto := SubStr((cAlias)->B1_COD, 1, 6)
		
		If Empty((cAlias)->ACU_COD) 
			//EnvEmail()
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		If Empty((cAlias)->B1_YFABRIC) 
			//EnvEmail()
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		cIdMarca := CadMarca((cAlias)->B1_YFABRIC, (cAlias)->Z4_NOME )
		
		cIdCateg := CadCategoria((cAlias)->ACU_DESC, (cAlias)->ACU_COD )
		
		If Empty(cIdMarca)
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		If Empty(cIdCateg)
			(cAlias)->(DbSkip())
			Loop
		EndIf
		
		cIdProduto := CadProduto(cIdMarca, cIdCateg)
		
		If !Empty(cIdProduto)
			CadImagens(cProdCmp, cIdProduto)
		EndIf
		
		(cAlias)->(DbSkip())
	EndDo

Return

//============================================================	
Static Function CadMarca(cNome, cCodigo)
	Local oMarca	:= AnyMarca():New()
	Local cId	 	:= ''
	
	oMarca:cCodigo 	:= cNome 
	oMarca:cNome	:= cCodigo
	oMarca:CriaMarca()
	
	cId	:= oMarca:cIdWeb
	
	//Marca
	DbSelectArea('SZ4')
	SZ4->(DbSetOrder(1)) //Marca
	If SZ4->(DbSEek(xFilial('SZ4')+cCodigo))
		RecLock('SZ4', .F.)
			SZ4->Z4_IDWEB := cId
		SZ4->(MsUnLock())
	EndIf
	
	FreeObj(oMarca)
	
	//Atualiza tabela marca
Return cId

//============================================================
Static Function CadCategoria(cNome, cCodigo)
	Local oCateg 	:= AnyCategoria():New()
	Local aSubCat	:= {}
	Local cId		:= ''
	Local nI		:= 0
	Local cCodPai	:= ''
	Local lAchou	:= .F.

	DbSElectArea('ACU')
	ACU->(DbSetOrder(1))

	While .T.
		If ACU->(dbSeek(xFilial('ACU')+cCodigo))
			aAdd(aSubCat, {ACU->ACU_COD, ACU->ACU_YIDWEB, ACU->ACU_DESC})
			cCodigo := ACU->ACU_CODPAI
		EndIf
		
		If Empty(cCodigo)
			Exit
		EndIf
	EndDo

	For nI := Len(aSubCat) to 1 STEP -1
		lAchou := .F.
		If !Empty(aSubCat[nI,2])
			lAchou 	:= oCateg:GetCateg(aSubCat[nI,2])
		EndIf
		
		If lAchou
			cId		:= oCateg:cIdWeb
		Else
			If ACU->(dbSeek(xFilial('ACU')+aSubCat[nI,1]))
				//Caso já existe, a classe só retorna o IdWeb
				oCateg:cCodigo := aSubCat[nI,1]
				oCateg:cIdWeb  := aSubCat[nI,2]
				oCateg:cNome   := aSubCat[nI,3]
				oCateg:cCodPai := cId
				oCateg:CriaCateg()
				cId := oCateg:cIdWeb
				
				If ACU->(dbSeek(xFilial('ACU')+oCateg:cCodigo))
					//If Empty(ACU->ACU_YIDWEB)
						RecLock('ACU', .F.)
							ACU->ACU_YIDWEB := cId
						ACU->(MsUnLock())
					//EndIf
				Endif 
			EndIf
		EndIf
	Next

	FreeObj(oCateg)
Return cId

//============================================================	
Static Function CadProduto(cIdMarca, cIdCateg)
	Local oProduto 	:= AnyProduto():New()
	Local oSku		:= nil
	Local cOrigANY	:= ''
	Local cInfor	:= ''
	Local cDescGar	:= ''
	Local nTempGar	:= 0
	Local nAltura	:= 0
	Local nLargura	:= 0
	Local nCompr	:= 0
	Local cProduto	:= SUBSTR((cAlias)->B1_COD, 1, 6)
	Local nI		:= 0
	
	//Analisa se já existe o produto 
	oProduto:cCodigo	:= (cAlias)->B1_COD
	If oProduto:GetProd()
		Return oProduto:cIdWeb
	EndIf
	 
	//Origem do Produto
	If (cAlias)->B1_ORIGEM $ '0/3/4/5/8/'
   		cOrigANY	:= '0' //Nacional
   	Else
   		cOrigANY	:= '1' //Importado
   	EndIf
   	
   	nAltura := Ceiling((cAlias)->B5_ALTURLC) //Altura
    nLargura:= Ceiling((cAlias)->B5_LARGLC)  //Largura
    nCompr	:= Ceiling((cAlias)->B5_COMPRLC) //Comprimento
    cInfor 	:= 'teste 1 '+chr(13)+chr(10)+'teste 2 ' //AllTrim((cAlias)->B5_ECAPRES)
    
    DbSelectArea('SB0')
	DbSetorder(1)
		
	If SB0->(DbSeek(xFilial('SB0')+(cAlias)->B1_COD))
		
		//A garantia no protheus está no formato de dias e no AnyMarket esta em meses
		nTempGar 	:= SB0->B0_DIASGAR
		If nTempGar > 0
			nTempGar /= 30
			
			nTempGar := NoRound(nTempGar, 0)
			
		EndIf
		
		cDescGar := cValToChar(nTempGar)+' MESES CONTRA DEFEITO DE FABRICACAO'
		
	Else
		nTempGar := 12 //meses
		cDescGar := '1 Ano de Garantia'
		
	EndIf
	
	oProduto:cCodigo 		:= (cAlias)->B1_COD
	oProduto:cIdMarca 		:= cIdMarca
	oProduto:cIdCateg 		:= cIdCateg 
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
	oProduto:cModelo		:= 'Teste'
	oProduto:cNBM			:= '29141100'
	

	AdicCaract(oProduto)
	AdicSku(oProduto)
	
	oProduto:CriaProduto()
	
	//Cadastra Produto X Web
	For nI := 1 to Len(oProduto:aSKUs)
		oSku := oProduto:aSKUs[nI]
		
		If !Empty(oSku:cIdWeb)
			DbSelectArea('SZ1')
			SZ1->(DbSetOrder(1)) //PRODUTO
			If SZ1->(DbSEek(xFilial('SZ1')+oSku:cCodProd))
				RecLock('SZ1', .F.)
			Else
				RecLock('SZ1', .T.)
				SZ1->Z1_PRODUTO := oSku:cCodProd
			EndIf
			
			SZ1->Z1_IDWEB := oSku:cIdWeb
			SZ1->(MsUnLock())
		EndIf
	Next
Return oProduto:cIdWeb

//============================================================
Static Function AdicSku(oAnyProd)
	Local oSku 	:= AnySku():New()	
	Local cProduto	:= SubStr( (cAlias)->B1_COD, 1, 6)
	Local cIdWeb	:= ''
	Local cDesc		:= ''
	Local cCodProd	:= ''
	Local cCodBarra	:= ''
	Local nEstoque	:= 0
	Local nPreco	:= 0

	DbSelectArea('SB0')
	DbSetorder(1)

	While !(cAlias)->(Eof()) .and. SubStr( (cAlias)->B1_COD, 1, 6) == cProduto		
		
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
		
		oAnyProd:AddSku(oSku)
		SB4->(DbSkip())
		
		(cAlias)->(dbSkip())
	EndDo

	FreeObj(oSku)
Return

//============================================================
Static Function AdicCaract(oAnyProd)
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
			oAnyProd:AddCaracte(oCaracte)
			SZ3->(DbSkip())
		EndDo
	EndIf

	FreeObj(oCaracte)
Return

//============================================================
Static Function CadImagens(cProduto, cIdProduto)
	Local cAlias	:= GetNextAlias()
	Local oImagem 	:= AnyImagem():New()
	Local cIdWeb	:= ''
	
	BeginSql Alias cAlias
		SELECT *
		FROM 
			%Table:SZ2% SZ2
		WHERE
			SZ2.Z2_FILIAL = %xFilial:SZ2%
			AND SZ2.%NOTDEL%
			AND SZ2.Z2_MSBLQL <> 'N'
			AND SZ2.Z2_PRODUTO = %Exp:cProduto%
	EndSql
	
	While !(cAlias)->(Eof())
		oImagem:cIdProduto 	:= cIdProduto 
		oImagem:cURL	 	:= (cAlias)->Z2_URL
		oImagem:CriaImagem()
		
		cIdWeb := oImagem:cIdWeb
		
		//Atualiza SZ2
		(cAlias)->(DbSkip())
	EndDo
	
	FreeObj(oImagem)
	(cAlias)->(DbCloseArea())
Return