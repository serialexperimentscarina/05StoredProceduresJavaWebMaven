CREATE DATABASE academia
USE academia

CREATE TABLE aluno(
codigo_aluno		INT				NOT NULL,
nome				VARCHAR(255)	NOT NULL
PRIMARY KEY (codigo_aluno)
)

CREATE TABLE atividade(
codigo				INT				NOT NULL,
descricao			VARCHAR(255)	NOT NULL,
imc					DECIMAL(7, 2)	NOT NULL
PRIMARY KEY (codigo)
)

CREATE TABLE atividadesaluno(
codigo_aluno		INT				NOT NULL,
altura				DECIMAL(7, 2)	NOT NULL,
peso				DECIMAL(7, 2)	NOT NULL,
imc					DECIMAL(7, 2)	NOT NULL,
atividade			INT				NOT NULL,
PRIMARY KEY (codigo_aluno),
FOREIGN KEY (codigo_aluno) REFERENCES aluno(codigo_aluno),
FOREIGN KEY (atividade) REFERENCES atividade(codigo)
)

INSERT INTO aluno VALUES
(1, 'Lain Iwakura'),
(2, 'Alice Mizuki'),
(3, 'Aoi Mukou'),
(4, 'Miyuki Sone'),
(5, 'Ui Shigure')

INSERT INTO atividade VALUES
(1, 'Corrida + Step', 18.5),
(2, 'Biceps + Costas + Pernas', 24.9),
(3, 'Esteira + Biceps + Costas + Pernas', 29.9),
(4, 'Bicicleta + Biceps + Costas + Pernas', 34.9),
(5, 'Esteira + Bicicleta', 39.9)

INSERT INTO atividadesaluno VALUES 
(1, 1.68, 43, 15.23, 1)

--Criar uma Stored Procedure (sp_alunoatividades), com as seguintes regras:
-- - Se, dos dados inseridos, o código for nulo, mas, existirem nome, altura, peso, deve-se inserir um
-- novo registro nas tabelas aluno e aluno atividade com o imc calculado e as atividades pelas
-- regras estabelecidas acima.
-- - Se, dos dados inseridos, o nome for (ou não nulo), mas, existirem código, altura, peso, deve-se
-- verificar se aquele código existe na base de dados e atualizar a altura, o peso, o imc calculado e
-- as atividades pelas regras estabelecidas acima.

CREATE PROCEDURE sp_alunoatividades(@codigo INT, @nome VARCHAR(255), @altura DECIMAL(7, 2), 
									@peso DECIMAL(7, 2))
AS
	IF (@altura IS NULL OR @peso IS NULL) 
	BEGIN
		RAISERROR('Altura ou peso nulos', 16, 1)
	END
	ELSE
	BEGIN
		IF (@codigo IS NULL AND @nome IS NULL) 
		BEGIN
			RAISERROR('Código e nome não podem ambos ser nulos', 16, 1)
		END
		ELSE
		BEGIN
			DECLARE @imc DECIMAL(7, 2)
			DECLARE @atividade INT
			IF (@codigo IS NULL) 
			BEGIN
				-- CASE 1
				DECLARE @pk INT
				SELECT @pk = MAX(codigo_aluno) FROM aluno
				SET @pk = @pk + 1
				SET @imc = (@peso / (POWER(@altura,2))) 
				SELECT @atividade =  MIN(codigo) FROM atividade WHERE imc > @imc
				IF (@atividade IS NULL)
				BEGIN
					SET @atividade = 5
				END
				INSERT INTO aluno VALUES (@pk, @nome)
				INSERT INTO atividadesaluno VALUES (@pk, @altura, @peso, @imc, @atividade)
			END
			ELSE
			BEGIN
				-- CASE 2
				IF ((SELECT nome FROM aluno WHERE codigo_aluno = @codigo) IS NOT NULL)
				BEGIN
					SET @imc = (@peso / (POWER(@altura,2))) 
					SELECT @atividade =  MIN(codigo) FROM atividade WHERE imc > @imc
					IF (@atividade IS NULL)
					BEGIN
						SET @atividade = 5
					END
					IF ((SELECT atividade FROM atividadesaluno WHERE codigo_aluno = @codigo) IS NOT NULL)
					BEGIN
						UPDATE atividadesaluno SET altura = @altura, peso = @peso, imc = @imc, atividade = @atividade WHERE codigo_aluno = @codigo
					END
					ELSE
					BEGIN
						INSERT INTO atividadesaluno VALUES (@codigo, @altura, @peso, @imc, @atividade)
					END
				END
				ELSE
				BEGIN
					RAISERROR('Não existe aluno com o código informado', 16, 1)
				END
			END
		END
	END

