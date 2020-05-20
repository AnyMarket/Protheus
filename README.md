# Protheus
Integração entre Anymarket e Protheus (TOTVS)

**IMPORTANTE**
========================

> O AnyMarket não mantem e/ou oferece suporte para a integração com o Protheus, apenas disponibilizamos a integração desenvolvida por um parceiro.

> Todos os includes do Protheus pode ser encontrado nesse [link], bastando apenas realizar uma consulta por "Includes".

Considerações
----------
 - A integração entre Protheus e o Anymarket, são utilizadas CLASSES na linguagem advpl, sendo estas responsáveis pela comunicação, inserção, consulta e atualização de dados através da API do Anymarket.

 - Estas CLASSES acessam o Anymarket através do padrão de comunicação Rest, sendo necessário um Token fornecido pelo AnyMarket.

 - As funções de envio de dados pelo Protheus possuem algumas limitações, elas não enviam descrições com caracteres especiais e por isso é feito um tratamento nos campos de descrições, alterando estes caracteres. Ex: O caractere “à” é alterado para “a”, o caractere “º” é alterado para “. ”. 

 Contribuições
-------------
Caso tenha encontrado ou corrigido um bug ou tem alguma fature em mente e queira dividir com a equipe [AnyMarket] ficamos muito gratos e sugerimos os passos a seguir:

 * Faça um fork.
 * Adicione sua feature ou correção de bug.
 * Envie um pull request no [GitHub].


 Mais informações
-------------
- Consultor: José Brittes
- E-mail: jrbrittes@gmail.com.br
- Tel: (27) 99792 - 0767


 [AnyMarket]: http://www.anymarket.com.br
 [GitHub]: https://github.com/AnyMarket/Protheus
 [link]: https://suporte.totvs.com/download
