-- SCRIPT UNIVERSAL DE RESET (À PROVA DE FALHAS)
-- Este script usa um bloco lógico para remover tabelas OU views sem dar erro.
-- Ele limpa qualquer resquício das tentativas anteriores.

DO $$ 
BEGIN
    -- 1. Tentar remover RESPOSTAS_ALUNOS (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.respostas_alunos CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.respostas_alunos CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 2. Tentar remover QUESTOES (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.questoes CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.questoes CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 3. Tentar remover PROVAS (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.provas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.provas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 4. Tentar remover ALUNOS (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.alunos CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.alunos CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 5. Tentar remover TURMAS (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.turmas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.turmas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 6. Tentar remover ESCOLAS (seja tabela ou view)
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.escolas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP VIEW IF EXISTS public.escolas CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- AGORA RECRIAMOS A ESTRUTURA LIMPA --

-- 1. Tabela de Escolas
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 2. Tabela de Provas (Sem FK rígida para evitar erros com classes)
CREATE TABLE public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID -- Guarda o ID da turma/classe, mas sem travar
);

-- 3. Tabela de Questões
CREATE TABLE public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- 4. Tabela de Respostas (Sem FK rígida para evitar erros com students)
CREATE TABLE public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID, -- Guarda o ID do aluno/student, mas sem travar
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT
);

-- 5. VIEWS para o App Flutter ler os dados originais
-- Converte 'classes' para 'turmas'
CREATE OR REPLACE VIEW public.turmas AS 
    SELECT id, name as nome, created_at 
    FROM public.classes;

-- Converte 'students' para 'alunos'
CREATE OR REPLACE VIEW public.alunos AS 
    SELECT id, name as nome, email, class_id as turma_id, access_code as matricula 
    FROM public.students;

-- 6. Habilitar Segurança (RLS)
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;

-- 7. Criar Políticas de Acesso Público
DO $$ 
BEGIN
    BEGIN CREATE POLICY "Public Access Escolas" ON public.escolas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Provas" ON public.provas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Questoes" ON public.questoes FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public Access Respostas" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;
