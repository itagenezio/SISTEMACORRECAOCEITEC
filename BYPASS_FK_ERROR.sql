-- SCRIPT DE EMERGÊNCIA (SEM TRAVAS DE SEGURANÇA)
-- Estratégia: Criar as tabelas SEM as chaves estrangeiras problemáticas (Foreign Keys)
-- Isso evita o erro "is not a table" instantaneamente.

-- 1. Limpeza
DROP TABLE IF EXISTS public.respostas_alunos;
DROP VIEW IF EXISTS public.respostas_alunos;

-- 2. Tabela de Escolas
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 3. Tabela de Provas
CREATE TABLE IF NOT EXISTS public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID NOT NULL -- Removida a referência direta para evitar erro
);

-- 4. Tabela de Questões
CREATE TABLE IF NOT EXISTS public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- 5. Tabela de Respostas (SEM FOREING KEY para 'alunos')
CREATE TABLE IF NOT EXISTS public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID NOT NULL, -- Apenas o ID, sem trava de banco de dados
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT
);

-- 6. Garantir que o App consiga LER os dados (Views)
CREATE OR REPLACE VIEW public.turmas AS 
    SELECT id, name as nome FROM public.classes;

CREATE OR REPLACE VIEW public.alunos AS 
    SELECT id, name as nome, class_id as turma_id, access_code as matricula FROM public.students;

-- 7. Atualizar código de acesso (opcional, mas bom pra evitar erro de permissão)
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    BEGIN CREATE POLICY "Public 1" ON public.escolas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public 2" ON public.provas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public 3" ON public.questoes FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Public 4" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;
