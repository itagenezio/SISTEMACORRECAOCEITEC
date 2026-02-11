-- SCRIPT DE LIMPEZA E INSTALAÇÃO LIMPA (CLEAN_INSTALL.sql)
-- Este script FORÇA a remoção de Views e Tabelas conflitantes antes de criar as novas.
-- Resolve erro "cannot drop columns from view" e "is not a table".

-- 1. DROP CASCADE (Apaga tudo que pode estar travando, seja Tabela ou View)
-- O CASCADE garante que se houver dependências, elas também somem.
DROP VIEW IF EXISTS public.respostas_alunos CASCADE;
DROP TABLE IF EXISTS public.respostas_alunos CASCADE;

DROP VIEW IF EXISTS public.questoes CASCADE;
DROP TABLE IF EXISTS public.questoes CASCADE;

DROP VIEW IF EXISTS public.provas CASCADE;
DROP TABLE IF EXISTS public.provas CASCADE;

DROP VIEW IF EXISTS public.alunos CASCADE;
DROP TABLE IF EXISTS public.alunos CASCADE;

DROP VIEW IF EXISTS public.turmas CASCADE;
DROP TABLE IF EXISTS public.turmas CASCADE;

-- 2. Recriar Tabelas do App (Modo Sem Travas - "Bypass FK")
-- Tabela de Escolas
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- Tabela de Provas (Sem FK rígida para evitar erros)
CREATE TABLE public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID -- Armazena o ID da 'classes', mas sem travar o banco
);

-- Tabela de Questões
CREATE TABLE public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- Tabela de Respostas (Sem FK rígida para 'alunos')
CREATE TABLE public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID, -- Armazena o ID de 'students', sem travar
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT
);

-- 3. Recriar as VIEWS para o App ler os dados originais
-- O App busca 'turmas', nós entregamos 'classes'
CREATE VIEW public.turmas AS 
    SELECT id, name as nome, created_at, '00000000-0000-0000-0000-000000000000'::uuid as escola_id 
    FROM public.classes;

-- O App busca 'alunos', nós entregamos 'students'
CREATE VIEW public.alunos AS 
    SELECT id, name as nome, email, class_id as turma_id, access_code as matricula 
    FROM public.students;

-- 4. Permissões de Segurança (Liberar tudo)
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    BEGIN CREATE POLICY "Public Access Escolas" ON public.escolas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Provas" ON public.provas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Questoes" ON public.questoes FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Respostas" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;
