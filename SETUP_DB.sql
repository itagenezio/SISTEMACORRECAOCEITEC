-- SCRIPT DE CONFIGURAÇÃO DO BANCO DE DADOS (SUPABASE)
-- Execute este script no SQL Editor do seu projeto Supabase para criar as tabelas necessárias.

-- 1. Tabela de Escolas
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 2. Tabela de Turmas
CREATE TABLE IF NOT EXISTS public.turmas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL,
    escola_id UUID REFERENCES public.escolas(id) ON DELETE CASCADE
);

-- 3. Tabela de Alunos
CREATE TABLE IF NOT EXISTS public.alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL,
    matricula TEXT,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE
);

-- 4. Tabela de Provas
CREATE TABLE IF NOT EXISTS public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE
);

-- 5. Tabela de Questões
CREATE TABLE IF NOT EXISTS public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- 6. Tabela de Respostas dos Alunos
CREATE TABLE IF NOT EXISTS public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID REFERENCES public.alunos(id) ON DELETE CASCADE,
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT,
    UNIQUE(aluno_id, questao_id)
);

-- POLÍTICAS DE SEGURANÇA (RLS - Permite tudo para facilitar desenvolvimento)
-- Habilita RLS para segurança futura, mas cria politica pública por enquanto

ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total escolas" ON public.escolas FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.turmas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total turmas" ON public.turmas FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.alunos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total alunos" ON public.alunos FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total provas" ON public.provas FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total questoes" ON public.questoes FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Acesso total respostas" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true);
