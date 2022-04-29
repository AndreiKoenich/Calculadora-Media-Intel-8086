; Porto Alegre, novembro de 2021
; Andrei Pochmann Koenich
; Matrícula: 00308680
; Trabalho de programação - Processador INTEL - Semestre 2021/1

; O programa a seguir possui a função de ler um arquivo em formato texto (arquivo de entrada), processar os dados lidos e, ao final, escrever um arquivo com os 
; resultados obtidos (arquivo de saída). No arquivo de entrada estará disponível uma lista de números que representam valores financeiros. O programa deverá
; ler esses valores e armazená-los na memória. Depois de lidos os números, o programa deverá calcular o dígito verificador de cada número, a soma dos valores e 
; a média aritmética deles. Finalmente, os valores lidos e calculados deverão ser escritos no arquivo de saída. Assume-se que, no arquivo texto de entrada, todos
; os números devem possuir um ou dois dígitos decimais. Somente são considerados números maiores que 0 e menores que 499,99. A parte inteira e a parte decimal dos 
; números pode estar separada por "." ou por ",". Caso exista algum caractere inválido em uma linha do arquivo texto de entrada, toda a linha é ignorada. Podem
; existir espaços em branco ou tabulações horizontais à esquerda ou à direita do número. Serão aceitos no máximo cem números válidos no arquivo texto de entrada.

	.model		small
	.stack

CR				EQU		0DH		; Constante que representa o retorno de cursor.
LF				EQU		0AH		; Constante que representa a quebra de linha.
TAB				EQU     09H		; Constante que representa a tabulação horizontal.

	.data
	
FileNameSrc		DB		256 DUP (?)		; Nome do arquivo a ser lido.
FileNameDst		DB		256 DUP (?)		; Nome do arquivo a ser criado.
FileHandleSrc	DW		0				; Handler do arquivo a ser lido.
FileHandleDst	DW		0				; Handler do arquivo a ser criado.
FileBuffer		DB		10 DUP (?)		; Buffer de leitura do arquivo.
FileNameBuffer	DB		150 DUP (?)		; Buffer de leitura do arquivo de entrada.
BufferAux		DB		256 DUP (?)		; Recebe string de cada linha.
StringAux		DB		10 DUP (?)		; Recebe strings que correspondem a números.

Count			DW		0	; Contador de posições do buffer.
Count2			DW		0	; Contador de posições das strings a serem impressas no arquivo de saída.
Numeracao		DW		0	; Contador da quantidade de números no arquivo de entrada.

Separador		DB		0	; Flag que indica se foi lido um ponto ou uma vírgula.
Ignora			DB		0	; Flag que indica se uma linha deve ser ignorada.
FoiInt			DB		0	; Flag que indica se um caractere da parte inteira do número foi lido.
FoiDec			DB		0	; Flag que indica se um caractere da parte decimal do número foi lido.
Acabou			DB		0	; Flag que indica se a leitura do arquivo de entrada foi encerrada.
EspacoDps       DB      0   ; Flag que indica se existem espaços em branco entre os números da parte decimal.
Arredonda		DB		0	; Flag que indica se o valor final será arredondado ou não.	

ParteInteira	DW		0	; Variável que contabiliza a soma das partes inteiras dos números.
ParteDecimal	DW		0	; Variável que contabiliza a soma das partes decimais dos números.
IntAux			DW		0	; Variável que recebe as partes inteiras dos números.
DecAux			DW 		0	; Variável que recebe as partes decimais dos números.
Quotient		DW 		0	; Variável que recebe o quociente de uma divisão.
Remainder		DW 		0	; Variável que recebe o resto de uma divisão.
AuxA			DW		0	; Variável auxiliar usada na divisão para obter a média.
AuxB			DW		0	; Variável auxiliar usada na divisão para obter a média.
AuxC			DW      2 DUP (?) ; Variável auxiliar usada na divisão para obter a média.
AuxD			DW		0	; Variável auxiliar usada para decidir sobre arredondamento.

Centena			DW		0	; Variável auxiliar que recebe o primeiro dígito da parte decimal da média.
Dezena			DW		0	; Variável auxiliar que recebe o segundo dígito da parte decimal da média.
Unidade			DW 		0	; Variável auxiliar que recebe o terceiro dígito da parte decimal da média.

FinalDec		DW		0	; Variável que recebe o valor final da média a ser impresso no arquivo de saída.

ParInt			DW		0	; Variável que recebe a paridade par da parte inteira dos números.
ParDec			DW		0	; Variável que recebe a paridade par da parte decimal dos números.

sw_n			DW		0	; Variável auxiliar usada para converter um número em string.
sw_f			DB		0	; Variável auxiliar usada para converter um número em string.
sw_m			DW		0	; Variável auxiliar usada para converter um número em string.

MsgPede			DB		"Nome do arquivo de entrada: ", 0
MsgErroOpen		DB		CR,LF,"Erro na abertura do arquivo.", CR, LF, 0
MsgErroCreate	DB		CR,LF,"Erro na criacao do arquivo.", CR, LF, 0
MsgErroRead		DB		CR,LF,"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWrite	DB		CR,LF,"Erro na escrita do arquivo.", CR, LF, 0
MsgCRLF			DB		CR, LF, 0
MsgSoma			DB		"Soma: ",0
MsgMedia		DB		"Media: ",0

	.code
	.startup

Inicio:

	CALL	GetFileNameSrc
	MOV		AL,0				; Realiza a abertura do arquivo texto de entrada com interrupção.
	LEA		DX,FileNameSrc
	MOV		AH,3DH
	INT		21H
	JNC		Continua			; Verifica se foi possível abrir o arquivo texto de entrada.
	
	LEA		BX,MsgErroOpen		; Informa que houve erro na abertura do arquivo texto de entrada.
	CALL	printf_s
	
	.exit	1					; Encerra o programa, pois houve erro na abertura do arquivo texto de entrada.
	
Continua:

	MOV		FileHandleSrc,AX	; Salva o handle do arquivo de entrada.
	
Continua1:

	CALL	GetFileNameDst		; Obtém o nome do arquivo de saída.
	LEA		DX,FileNameDst
	CALL	fcreate				; Cria ou substitui o arquivo de saída.
	MOV		FileHandleDst,BX
	JNC		Again				; Inicia a leitura do arquivo de entrada.
	MOV		BX,FileHandleSrc
	CALL	fclose				; Fecha o arquivo de entrada, pois houve erro na leitura.
	LEA		BX,MsgErroCreate
	CALL	printf_s
	JMP		Final				; Encerra o programa.

Again:							; Faz a leitura de um caractere por vez do arquivo de entrada.

	MOV		BX,FileHandleSrc
	MOV		AH,3FH
	MOV		CX,1
	LEA		DX,FileBuffer
	INT		21H
	JNC		Continua2		; Verifica se houve erro de leitura.
	
	LEA		BX,MsgErroRead
	CALL	printf_s
	
	MOV		AL,1
	JMP		ErroLeitura		; Encerra o programa, pois houve erro de leitura.
	

Continua2:					

	CMP		AX,0	
	JNE		AnalisaBuffer	; Analisa o caractere armazenado no buffer de leitura.

	MOV		AL,0
	JMP		AnalisaFinal	; Encerra a leitura do arquivo.
	
AnalisaFinal:

	CMP		Ignora,0		; Verifica se uma última linha será tratada.
	JNE		CloseAndFinal
	CMP		FoiInt,1		; Verifica se uma última linha será tratada.
	JNE		CloseAndFinal
	CMP		FoiDec,1		; Verifica se uma última linha será tratada.
	JNE		CloseAndFinal
	MOV		Acabou,1		; Verifica se uma última linha será tratada.
	JMP		TrataDecimal

AnalisaBuffer:

	CMP		FileBuffer,LF	; Verifica se há quebra de linha, para avançar para outra linha.
	JE		Reseta
	
	CMP		FileBuffer,CR	; Verifica se há retorno de cursor, para avançar para outra linha.
	JE		Reseta
	
	CMP		Numeracao,99	; Verifica se o limite de cem números foi atingido.
	JA		CloseAndFinal
	
	CMP		Ignora,1		; Verifica se a linha será ignorada.
	JE		Again
	
	CMP		FileBuffer,'.'	; Verifica se um separador (ponto) foi encontrado.
	JE		TrataSeparador
	CMP		FileBuffer,','	; Verifica se um separador (vírgula) foi encontrado.
	JE		TrataSeparador

	CMP		FileBuffer,' '	; Verifica se encontrou um espaço.
	JE		TestaEspaco
	CMP		FileBuffer,TAB	; Verifica se encontrou uma tabulação horizontal.
	JE		TestaEspaco

	CMP		FileBuffer,'0'	; Verifica se o caractere possui valor ASCII dentro da faixa aceitável.
	JB		TrataInvalido
	CMP		FileBuffer,'9'	; Verifica se o caractere possui valor ASCII dentro da faixa aceitável.
	JA		TrataInvalido
	
	CMP		Count,2			; Ignora números com mais caracteres do que o permitido.
	JA		TrataInvalido
	
	CMP     EspacoDps,1     ; Verifica se existem espaços entre os números da parte decimal.
	JE      TrataInvalido
	
	CMP		Separador,0		
	JNE		TestaDps
	MOV		FoiInt,1		; Informa na flag que um número inteiro válido foi armazenado.
	
TestaDps:
	
	CMP		Separador,1
	JNE		Continua3
	MOV		FoiDec,1		; Informa na flag que um número decimal válido foi armazenado.

	JMP 	Continua3
	
TestaEspaco:				; Verifica se existem espaços em branco entre os dígitos do número.

	CMP 	FoiInt,1
	JNE		Again
	CMP		Separador,0
	JE		TrataInvalido
	CMP     FoiDec,0
	JE      TrataInvalido
	MOV     EspacoDps,1
	JMP     Again
	
Reseta:

	CMP		Ignora,1		; Verifica se a linha será ignorada.
	JE		Reseta2
	
	CMP		FoiInt,1		; Verifica se a parte inteira do número foi armazenada.
	JNE		Reseta2

	CMP		FoiDec,1		; Verifica se a parte decimal do número foi armazenada.
	JNE		Reseta2
	
	JMP		TrataDecimal	; Atualiza o valor decimal das variáveis.
	
TrataDecimal:
	
	MOV		BX,Count
	LEA		BX,BufferAux[BX]
	MOV		byte ptr[BX],0
	
	CMP		Count,2			; Ignora números com mais de dois caracteres decimais.
	JA		Reseta2

	LEA		BX,BufferAux
	CALL	atoi			; Converte a string em um valor numérico.
	
	MOV		DecAux,AX
	
	CMP		Count,1			; Verifica se a parte decimal possui apenas um caractere.
	JNE		EncerraLinha	
	MOV		AX,DecAux
	MOV		BX,10
	MUL		BX				; Multiplica a parte decimal por 10, para adequá-la.
	MOV		DecAux,AX
	
EncerraLinha:

	INC		Numeracao	; Incrementa o contador de números.
	
	JMP		Saida		; Faz a impressão no arquivo de saída.
	
EncerraLinha2:
	
	CMP		Acabou,1		; Verifica se a leitura do arquivo de entrada acabou.
	JE		CloseAndFinal
	
	JMP 	Reseta2			; Reinicia as flags para leitura de nova linha.
	
SomaValores:

	MOV		AX,ParteInteira	
	ADD		AX,IntAux		; Atualiza a soma das partes inteiras dos números.
	
	MOV		ParteInteira,AX

	MOV		AX,ParteDecimal
	ADD		AX,DecAux
	
	CMP		AX,99			; Tratamento de overflow das somas das partes decimais dos números.
	JA		OFdec
	
SomaValores2:

	MOV		ParteDecimal,AX
	JMP		EncerraLinha2
	
OFdec:

	INC		ParteInteira	; Incrementa a soma dos inteiros em uma unidade.
	SUB		AX,100			; Subtrai a parte decimal em 100 unidades após o overflow na soma.
	JMP		SomaValores2
	
Reseta2:

	CMP		Acabou,1		; Verifica se a leitura do arquivo de entrada acabou.
	JE		CloseAndFinal
	
	MOV		IntAux,0		; Reinicia a variável que armazena as partes inteiras dos números.
	MOV		DecAux,0		; Reinicia a variável que armazena as partes decimais dos números.

	MOV		Count,0			; Reinicia as variáveis de análise das linhas.
	MOV		Ignora,0
	MOV		Separador,0
	MOV		FoiInt,0
	MOV		FoiDec,0
	MOV     EspacoDps,0
	JMP		Again			; Continua a leitura do arquivo de entrada.

TrataSeparador:

	CMP		Separador,1		; Verifica se mais de um separador foi inserido na linha do arquivo de entrada.
	JE		TrataInvalido
	MOV		Separador,1		; Atualiza a flag que indica presença de separador na linha do arquivo de entrada.
	CMP		FoiInt,0
	JE		TrataInvalido	; Ignora o resto da linha.
	JMP		TrataInteiro	; Atualiza a soma das partes inteiras dos números.
	
TrataInteiro:

	MOV		BX,Count
	LEA		BX,BufferAux[BX]
	MOV		byte ptr[BX],0

	LEA		BX,BufferAux
	CALL	atoi			; Converte a string em um valor numérico.
	
	CMP		AX,500			; Verifica se o valor da parte inteira é maior do que o aceitável.
	JNAE	TrataInteiro2	; Atualiza a soma das partes inteiras dos números.
	JMP		TrataInvalido	; Ignora o resto da linha.
	
TrataInteiro2:
	
	MOV		IntAux,AX
	MOV		Count,0		; Reinicia o contador de posições do buffer auxiliar.
	JMP 	Again		; Continua a leitura do arquivo de entrada.
	
TrataInvalido:
	
	MOV		Ignora,1	; Ignora o resto da linha.
	JMP		Again		; Continua a leitura do arquivo de entrada.
	
Continua3:
	
	MOV		BX,Count
	LEA		BX,BufferAux[BX]
	MOV		AL,FileBuffer
	MOV		byte ptr [BX],AL
	INC		Count				; Incrementa o contador de posições do buffer auxiliar.
	JMP		Again				; Continua a leitura do arquivo de entrada.

Saida:

	MOV		AX,IntAux
	ADD		AL,0
	JP		SaidaAux	; Verifica a paridade par da parte inteira.
	JMP		SaidaAux2
	
SaidaAux:

	ADD		AH,0
	JP		ParidadeInt1	
	JMP		ParidadeInt2

SaidaAux2:

	ADD		AH,0
	JP		ParidadeInt2	
	JMP		ParidadeInt1	

ParidadeInt1:

	MOV		ParInt,0
	JMP		Testa1 
	
ParidadeInt2:

	MOV		ParInt,1
	JMP		Testa1		; Verifica a paridade par da parte decimal.
	
Testa1:

	MOV		AX,DecAux
	ADD		AL,0
	JP		ParidadeDec1
	JMP		ParidadeDec2
	
ParidadeDec1:

	MOV		ParDec,0
	JMP		Testa2
	
ParidadeDec2:

	MOV		ParDec,1
	JMP		Testa2
	
Testa2:
	
	CMP		Numeracao,10
	JB		Saida2
	CMP		Numeracao,100
	JB		Saida3
	JMP		Saida4
	
SaidaA:

	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.

	CMP		IntAux,10
	JB		Saida5
	CMP		IntAux,100
	JB		Saida6
	JMP		Saida7
	
SaidaB:

	CALL	ImprimeVirgula	; Faz a impressão no arquivo de saída, na formatação correta.
	
	CMP		DecAux,10
	JB		Saida8
	JMP		Saida9
	
SaidaC:

	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.
	CALL	ImprimeTraco	; Faz a impressão no arquivo de saída, na formatação correta.
	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.
	
	MOV		AX,ParInt		; Imprime o valor da paridade par da parte inteira na saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	CALL	ImprimeString
	MOV		AX,ParDec		; Imprime o valor da paridade par da parte decimal na saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	CALL	ImprimeString
	CALL	QuebraLinha		; Realiza quebra de linha no arquivo de saída.
	JMP		SomaValores

Saida2:

	CALL	ImprimeZero		; Faz a impressão no arquivo de saída, na formatação correta.
	
Saida3:

	CALL	ImprimeZero		; Faz a impressão no arquivo de saída, na formatação correta.
	
Saida4:

	MOV		AX,Numeracao	; Imprime a numeração de cada número no arquivo de saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	
	CALL	ImprimeString	; Faz a impressão no arquivo de saída, na formatação correta.
	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.
	CALL	ImprimeTraco	; Faz a impressão no arquivo de saída, na formatação correta.
	
	JMP		SaidaA
	
Saida5:

	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.
	
Saida6:

	CALL	ImprimeEspaco	; Faz a impressão no arquivo de saída, na formatação correta.
	
Saida7:

	MOV		AX,IntAux		; Faz a impressão das partes inteiras dos números no arquivo de saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	CALL	ImprimeString	
	JMP		SaidaB
	
Saida8:

	CALL	ImprimeZero		; Faz a impressão no arquivo de saída, na formatação correta.
	
Saida9:

	MOV		AX,DecAux		; Faz a impressão das partes decimais dos números no arquivo de saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	CALL	ImprimeString	
	JMP		SaidaC
	
CloseAndFinal:
	
	CALL	ImprimeSoma			; Imprime a mensagem de soma no arquivo de saída.

	MOV		AX,ParteInteira		; Imprime a soma total dos valores inteiros dos números no arquivo de saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	
	LEA		BX,StringAux
	CALL	ImprimeString
	
	CALL	ImprimeVirgula		; Faz a impressão no arquivo de saída, na formatação correta.
	
	CMP		ParteDecimal,10
	JB		Final_2
	JMP		Final_3
	
Final_2:

	CALL	ImprimeZero		; Faz a impressão no arquivo de saída, na formatação correta.
	
Final_3:

	MOV		AX,ParteDecimal		; Imprime a soma total dos valores decimais dos números no arquivo de saída.
	LEA		BX,StringAux
	CALL	sprintf_w
	LEA		BX,StringAux
	CALL	ImprimeString
	
Final_4:
	
	CALL	QuebraLinha			; Realiza quebra de linha no arquivo de saída.
	
	LEA		BX,MsgMedia			; Imprime a mensagem de média no arquivo de saída.
	CALL	ImprimeMedia
	
	CALL	Divide

	MOV		BX,FileHandleSrc	; Fecha o arquivo de entrada.
	CALL	fclose
	
	MOV		BX,FileHandleDst	; Fecha	o arquivo de saída.
	CALL	fclose
	
Final:
	.exit						; Encerra a execução do programa.
	
ErroEscrita:

	LEA		BX, MsgErroWrite	
	CALL	printf_s
	
ErroLeitura:

	MOV		BX,FileHandleSrc		; Fecha arquivo de entrada.
	CALL	fclose
	MOV		BX,FileHandleDst		; Fecha arquivo de saída.
	CALL	fclose
	JMP		Final					; Encerra a execução do programa.

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GetFileNameSrc	proc	near				; Função para obter o nome do arquivo de entrada com o teclado.

	LEA		BX,MsgPede						; Solicita o nome do arquivo de entrada ao usuário.
	CALL	printf_s

	MOV		AH,0AH							; Obtém o nome do arquivo de entrada com o teclado.
	LEA		DX,FileNameBuffer
	MOV		byte ptr FileNameBuffer,100
	INT		21H
		
	LEA		SI,FileNameBuffer+2
	LEA		DI,FileNameSrc
	MOV		CL,FileNameBuffer+1
	MOV		CH,0
	MOV		AX,ds						
	MOV		ES,AX
	REP 	MOVsb

	MOV		byte ptr ES:[DI],0
	RET
	
GetFileNameSrc	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GetFileNameDst	proc	near		; Função para obter o nome do arquivo de saída, adicionando ".res" no arquivo de entrada.

	MOV		Count2,0
	
GetDst1:							; Copia o nome do arquivo de entrada.
	
	MOV		BX,Count2
	LEA		BX,FileNameSrc[BX]
	MOV		AL,byte ptr[BX]
	CMP		AL,0
	JE		GetDst2
	CMP		AL,'.'
	JE		GetDst2
	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],AL
	INC		Count2
	JMP		GetDst1
	
GetDst2:							; Adiciona a extensão ".res" no nome do arquivo de saída.

	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],'.'
	INC		Count2
	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],'r'
	INC		Count2
	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],'e'
	INC		Count2
	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],'s'
	INC		Count2
	MOV		BX,Count2
	LEA		BX,FileNameDst[BX]
	MOV		byte ptr[BX],0
	
	RET
	
GetFileNameDst	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sprintf_w	proc	near	; Função para converter número em string, que recebe a string-destino em BX e o número em AX.

	MOV		sw_n,AX
	MOV		CX,5
	MOV		sw_m,10000
	MOV		sw_f,0
	
sw_do:

	MOV		DX,0		
	MOV		AX,sw_n
	DIV		sw_m
	
	CMP		AL,0
	JNE		sw_store
	CMP		sw_f,0
	JE		sw_continue
	
sw_store:

	ADD		AL,'0'
	MOV		[BX],AL
	INC		BX
	MOV		sw_f,1
	
sw_continue:
	
	MOV		sw_n,DX		
	MOV		DX,0
	MOV		AX,sw_m
	MOV		BP,10
	DIV		BP
	MOV		sw_m,AX
	DEC		CX
	
	CMP		CX,0
	JNZ		sw_do
	
	CMP		sw_f,0
	JNZ		sw_continua2
	MOV		[BX],'0'
	INC		BX
	
sw_continua2:

	MOV		byte ptr[BX],0		; Adiciona zero no final da string.

	RET

sprintf_w	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

printf_s	proc	near	; Função para receber uma string em BX e imprimi-la na tela.

	MOV		DL,[BX]
	CMP		DL,0
	JE		ps_1

	PUSH	BX				; Faz a impressão com a interrupção correspondente.
	MOV		AH,2
	INT		21H
	POP		BX

	INC		BX		
	JMP		printf_s
		
ps_1:

	RET
	
printf_s	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

atoi	proc near			; Função para converter uma string recebida em BX em um número retornado em AX.

	MOV		AX,0
		
atoi_2:

	CMP		byte ptr[BX], 0
	JZ		atoi_1

	MOV		CX,10
	MUL		CX

	MOV		CH,0
	MOV		CL,[BX]
	ADD		AX,CX

	SUB		AX,'0'

	INC		BX
	
	JMP		atoi_2

atoi_1:

	RET

atoi	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fcreate	proc	near	; Função para criar um arquivo cujo nome está em DX. Retorna o handle do arquivo em BX e deixa a flag carry em "0" se o arquivo foi criado corretamente.

	MOV		CX,0
	MOV		AH,3CH
	INT		21H
	MOV		BX,AX
	RET
	
fcreate	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fclose	proc	near	; Função para fechar um arquivo cujo handle está em BX. Deixa a flag carry em "0" se o arquivo foi fechado corretamente.

	MOV		AH,3EH
	INT		21H
	RET
	
fclose	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

setChar	proc	near	; Função para escrever um caractere no arquivo de saída, que recebe o handle do arquivo em BX e o caractere em DL.

	MOV		AH,40H
	MOV		CX,1
	MOV		FileBuffer,DL
	LEA		DX,FileBuffer
	INT		21H
	RET					; Retorna o número de caracteres escritos em AX e deixa a flag carry em "0" se a escrita ocorreu normalmente.
	
setChar	endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeEspaco	proc	near	; Função para imprimir um espaço em branco no arquivo de saída.

	MOV		BX,FileHandleDst
	MOV		DL,' '
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	RET
	
ImprimeEspaco endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeZero	proc	near	; Função para imprimir um zero no arquivo de saída.

	MOV		BX,FileHandleDst
	MOV		DL,'0'
	CALL	setChar
	JC		ErroEscrita		; Verifica se houve erro na escrita, para encerrar o programa.
	RET
	
ImprimeZero endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeTraco	proc	near	; Função para imprimir um traço no arquivo de saída.	

	MOV		BX,FileHandleDst	
	MOV		DL,'-'
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	RET
	
ImprimeTraco endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeVirgula	proc	near	; Função para imprimir uma vírgula no arquivo de saída.	

	MOV		BX,FileHandleDst
	MOV		DL,','
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	RET
	
ImprimeVirgula endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

QuebraLinha	proc	near		; Função para realizar uma quebra de linha no arquivo de saída.	

	MOV		BX,FileHandleDst	
	MOV		DL,CR
	CALL	setChar
	JC		ErroEscrita	
	MOV		BX,FileHandleDst
	MOV		DL,LF
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	RET
	
QuebraLinha endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeString	proc	near	; Função para imprimir uma string inteira no arquivo de saída. Recebe a string em BX, na variável StringAux.

	MOV		Count2,0
	
ImprimeString2:

	MOV		BX,Count2
	LEA		BX,StringAux[BX]	; Percorre cada caractere da string, e imprime um por vez na saída.
	MOV		AL,byte ptr [BX]
	CMP		AL,0
	JE		ImprimeStringFim
	INC		Count2
	MOV		DL,AL
	MOV		BX,FileHandleDst
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	JMP		ImprimeString2
		
ImprimeStringFim:

	RET

ImprimeString endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeSoma	proc	near		; Função para imprimir a mensagem de soma no arquivo de saída.

	MOV		Count2,0
	
ImprimeSoma2:

	MOV		BX,Count2
	LEA		BX,MsgSoma[BX]		; Percorre cada caractere da string, e imprime um por vez na saída.
	MOV		AL,byte ptr [BX]
	CMP		AL,0
	JE		ImprimeSomaFim
	INC		Count2
	MOV		DL,AL
	MOV		BX,FileHandleDst
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	JMP		ImprimeSoma2
	
ImprimeSomaFim:

	RET

ImprimeSoma endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprimeMedia	proc	near	; Função para imprimir a mensagem de média no arquivo de saída.

	MOV		Count2,0
	
ImprimeMedia2:

	MOV		BX,Count2
	LEA		BX,MsgMedia[BX]		; Percorre cada caractere da string, e imprime um por vez na saída.
	MOV		AL,byte ptr [BX]
	CMP		AL,0
	JE		ImprimeMediaFim
	INC		Count2
	MOV		DL,AL
	MOV		BX,FileHandleDst
	CALL	setChar
	JC		ErroEscrita			; Verifica se houve erro na escrita, para encerrar o programa.
	JMP		ImprimeMedia2
	
ImprimeMediaFim:

	RET

ImprimeMedia endp
	
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Divide		proc 	near

	CMP		Numeracao,0			; Verifica se algum número válido foi inserido.
	JE		SemNumeros

	MOV		BX,Numeracao		; Realiza a divisão entre a parte inteira e o total de números.
	MOV		AX,ParteInteira
	MOV		DX,0
	DIV		BX
	MOV		Quotient,AX
	MOV		Remainder,DX	    ; Armazena o resto da divisão.
	
	MOV     AX,1000
	MUL     Remainder
	MOV     AuxC,AX
	MOV     AuxC+2,DX	

	MOV 	BX,Numeracao	; Divide resto (que foi multiplicado mil) pela quantidade de termos e coloca em AuxA.
	MOV		AX,AuxC
	MOV		DX,AuxC+2
	DIV		BX	
	MOV		AuxA,AX						
	
	MOV		AX,ParteDecimal ; Divisão da parte fracionária.	
	MOV		AuxB,AX
	
	MOV		AX,AuxB 		; Multiplica a parte fracionária por dez.
	MOV     BX,10
	MUL		BX
	MOV		AuxB,AX
	
	MOV		BX,Numeracao	; Divide a parte fracionária (que foi multiplicada por dez) pela quantidade de termos e coloca em AuxB.
	MOV		AX,AuxB
	MOV		DX,0
	DIV		BX
	MOV		AuxB,AX
	
	MOV     AX,AuxA  	; Faz a soma entre AuxA e AuxB, e armazena o resultado em AuxA.
	ADD		AX,AuxB
	MOV		AuxA,AX
	
	CALL	AnalisaRound	; Verifica se o valor final será arredondado.
	CALL 	Round			; Arredonda o valor final da média, se necessário.
	
Fim1:

	MOV		AX,Quotient 	; Imprime a parte inteira do quociente e uma vírgula no arquivo de saída.
	LEA		bx,StringAux
	CALL	sprintf_w
	LEA		bx,StringAux
	CALL	ImprimeString
	CALL	ImprimeVirgula
	
	CMP     FinalDec,10
	JAE		Fim2
	CALL	ImprimeZero
	
Fim2:

	MOV		AX,FinalDec		; Imprime a parte inteira decimal da média no arquivo de saída.
	LEA		bx,StringAux
	CALL	sprintf_w
	LEA		bx,StringAux
	CALL	ImprimeString
	RET
	
SemNumeros:					; Considera que a média vale zero, pois nenhum número válido foi inserido.

	CALL ImprimeZero
	CALL ImprimeVirgula
	CALL ImprimeZero
	CALL ImprimeZero
	RET
	
Divide		endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

AnalisaRound		proc 	near	; Função para analisar se o valor final será arredondado ou não.

	MOV     AX,100
	MUL     Remainder
	ADD     AX,ParteDecimal
	MOV     BX,Numeracao
	DIV 	BX
	MOV     AuxD,DX
	
	MOV		AX,2
	MUL     AuxD
	CMP     AX,Numeracao
	JB      AnalisaRoundFim
	MOV		Arredonda,1
	
AnalisaRoundFim:

	RET
	
AnalisaRound		endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Round		proc 	near	; Função para arredondar o valor final da média, se necessário.

	MOV BX,10
	
	MOV AX,AuxA
	MOV DX,0
	DIV BX
	MOV Unidade,DX
	MOV AuxA,AX
	
	MOV AX,AuxA
	MOV DX,0
	DIV BX
	MOV Dezena,DX
	MOV AuxA,AX
	
	MOV AX,AuxA
	MOV DX,0
	DIV BX
	MOV Centena,DX
	MOV AuxA,AX

	CMP	Unidade,5
	JAE Arruma1
	CMP Arredonda,1
	JE	Arruma1
	JMP Round2
	
Arruma1:			; Tratamento de overflow do segundo dígito da parte decimal.

	INC Dezena
	CMP Dezena,10
	JE	Arruma2
	JMP Round2
	
Arruma2:			; Tratamento de overflow do primeiro dígito da parte decimal.

	MOV Dezena,0
	INC Centena
	CMP Centena,10
	JE 	Arruma3
	JMP Round2
	
Arruma3:			; Tratamento de overflow da parte inteira do valor final da média.

	MOV Centena,0
	INC Quotient
	JMP Round2
	
Round2:
	
	MOV	AX,Centena
	MOV BX,10
	MUL BX
	ADD AX,Dezena
	MOV FinalDec,AX

	RET
	
Round		endp

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	end