-- SCRIPT DE REINICIALIZAÇÃO COMPLETA (RESET)
-- ATENÇÃO: ISSO APAGARÁ TODOS OS DADOS DESSAS TABELAS ESPECÍFICAS
-- Use para corrigir o erro "is not a table" (geralmente causado por conflito com Views antigas)

-- 1. Dropar (apagar) tabelas antigas para evitar conflitos de tipo
DROP TABLE IF EXISTS public.respostas_alunos CASCADE;
DROP TABLE IF EXISTS public.questoes CASCADE;
DROP TABLE IF EXISTS public.provas CASCADE;
DROP TABLE IF EXISTS public.alunos CASCADE;
DROP TABLE IF EXISTS public.turmas CASCADE;
DROP TABLE IF EXISTS public.escolas CASCADE;

-- Também removemos views caso existam com esses nomes
DROP VIEW IF EXISTS public.respostas_alunos CASCADE;
DROP VIEW IF EXISTS public.questoes CASCADE;
DROP VIEW IF EXISTS public.provas CASCADE;
DROP VIEW IF EXISTS public.alunos CASCADE;
DROP VIEW IF EXISTS public.turmas CASCADE;
DROP VIEW IF EXISTS public.escolas CASCADE;

-- 2. Recriar Tabelas na ordem correta (para respeitar as chaves estrangeiras)

-- Tabela de Escolas
CREATE TABLE public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- Tabela de Turmas
CREATE TABLE public.turmas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL,
    escola_id UUID REFERENCES public.escolas(id) ON DELETE CASCADE
);

-- Tabela de Alunos
CREATE TABLE public.alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL,
    matricula TEXT,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE
);

-- Tabela de Provas
CREATE TABLE public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE
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

-- Tabela de Respostas dos Alunos
CREATE TABLE public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID REFERENCES public.alunos(id) ON DELETE CASCADE,
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT,
    UNIQUE(aluno_id, questao_id)
);

-- 3. Configurar Políticas de Segurança (RLS)
-- Habilita RLS
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.turmas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alunos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;

-- Cria politicas de acesso total (para desenvolvimento)
CREATE POLICY "Acesso total escolas" ON public.escolas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acesso total turmas" ON public.turmas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acesso total alunos" ON public.alunos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acesso total provas" ON public.provas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acesso total questoes" ON public.questoes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acesso total respostas" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true);
