-- SCRIPT DE CORREÇÃO DEFINITIVA (Execute APENAS este script)
-- Este script ignora as tentativas anteriores e corrige o erro de relacionamento.

-- 1. Remover a tabela problemática se ela existir com definição errada
DROP TABLE IF EXISTS public.respostas_alunos;

-- 2. Garantir que a tabela ESCOLAS existe
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 3. Atualizar CLASSES para ter escola_id (Necessário para a view 'turmas')
ALTER TABLE public.classes ADD COLUMN IF NOT EXISTS escola_id UUID REFERENCES public.escolas(id) ON DELETE SET NULL;

-- 4. Tabela PROVAS (Referencia CLASSES, não 'turmas')
CREATE TABLE IF NOT EXISTS public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID REFERENCES public.classes(id) ON DELETE CASCADE
);

-- 5. Tabela QUESTOES
CREATE TABLE IF NOT EXISTS public.questoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    numero INTEGER NOT NULL,
    enunciado TEXT,
    gabarito TEXT NOT NULL,
    prova_id UUID REFERENCES public.provas(id) ON DELETE CASCADE
);

-- 6. Tabela RESPOSTAS_ALUNOS (Referencia STUDENTS, não 'alunos')
-- CORREÇÃO CRÍTICA: Chave estrangeira aponta para a tabela real 'students'
CREATE TABLE IF NOT EXISTS public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT,
    UNIQUE(aluno_id, questao_id)
);

-- 7. Recriar VIEWS para compatibilidade com o App Flutter e Supabase
-- O Flutter acessa 'turmas', o banco entrega 'classes'
CREATE OR REPLACE VIEW public.turmas AS 
    SELECT id, name as nome, created_at, escola_id 
    FROM public.classes;

-- O Flutter acessa 'alunos', o banco entrega 'students'
CREATE OR REPLACE VIEW public.alunos AS 
    SELECT id, name as nome, email, class_id as turma_id, access_code as matricula 
    FROM public.students;

-- 8. Permissões
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
