-- SCRIPT DE INTEGRAÇÃO SEGURO (NÃO APAGA DADOS ANTIGOS)
-- Este script adapta o banco de dados existente (Inovatec) para funcionar com o novo App de Correção.

-- 1. Tabela de Escolas (Nova funcionalidade, criamos se não existir)
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 2. Adaptar Tabela CLASSES (Turmas) existente
-- Adicionamos escola_id para o app funcionar, sem quebrar o que já existe
ALTER TABLE public.classes ADD COLUMN IF NOT EXISTS escola_id UUID REFERENCES public.escolas(id) ON DELETE SET NULL;

-- 3. Criar VIEWS para o App Flutter (Traduz "classes" para "turmas")
-- Isso permite que o Flutter leia/escreva em "turmas" mas grave em "classes"
CREATE OR REPLACE VIEW public.turmas AS 
    SELECT 
        id, 
        name as nome, 
        escola_id 
    FROM public.classes;

-- 4. Adaptar Tabela STUDENTS (Alunos)
-- Garantimos que campos opcionais no novo app não quebrem o banco
ALTER TABLE public.students ALTER COLUMN access_code DROP NOT NULL;

-- 5. Criar VIEWS para o App Flutter (Traduz "students" para "alunos")
CREATE OR REPLACE VIEW public.alunos AS 
    SELECT 
        id, 
        name as nome, 
        access_code as matricula, 
        class_id as turma_id 
    FROM public.students;

-- 6. Tabela de Provas (Conecta com CLASSES)
CREATE TABLE IF NOT EXISTS public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID REFERENCES public.classes(id) ON DELETE CASCADE
);

-- 7. Tabela de Questões
CREATE TABLE IF NOT EXISTS public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- 8. Tabela de Respostas (Conecta com STUDENTS e QUESTOES)
-- AQUI ESTAVA O ERRO: Referenciava "alunos" (view) em vez de "students" (tabela)
CREATE TABLE IF NOT EXISTS public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT,
    UNIQUE(aluno_id, questao_id)
);

-- 9. Políticas de Segurança (Para garantir acesso e evitar erros de permissão)
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_alunos ENABLE ROW LEVEL SECURITY;

-- Políticas permissivas para desenvolvimento
DO $$ 
BEGIN
    BEGIN CREATE POLICY "Acesso total escolas" ON public.escolas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Acesso total provas" ON public.provas FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Acesso total questoes" ON public.questoes FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN CREATE POLICY "Acesso total respostas" ON public.respostas_alunos FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;
