-- SCRIPT DE CORREÇÃO FINAL (FIX_DB_FINAL.sql)
-- Este script resolve o erro "referenced relation 'alunos' is not a table"
-- Ele cria as relações apontando para as tabelas ORIGINAIS (students e classes)

-- 1. Limpeza de tabelas que podem estar com definições erradas (apenas as novas)
DROP TABLE IF EXISTS public.respostas_alunos;
-- Não dropamos questoes nem provas para preservar dados se ja existirem, usamos IF NOT EXISTS abaixo

-- 2. Tabela de Escolas (Nova)
CREATE TABLE IF NOT EXISTS public.escolas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nome TEXT NOT NULL
);

-- 3. Atualizar Tabela CLASSES (Adicionar vinculo com escola)
ALTER TABLE public.classes ADD COLUMN IF NOT EXISTS escola_id UUID REFERENCES public.escolas(id) ON DELETE SET NULL;

-- 4. Tabela de Provas (Atrelada a CLASSES, não a 'turmas')
CREATE TABLE IF NOT EXISTS public.provas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    titulo TEXT NOT NULL,
    turma_id UUID REFERENCES public.classes(id) ON DELETE CASCADE
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

-- 6. Tabela de Respostas (Atrelada a STUDENTS, não a 'alunos')
-- AQUI ESTÁ A CORREÇÃO DO SEU ERRO:
CREATE TABLE IF NOT EXISTS public.respostas_alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    aluno_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    questao_id UUID REFERENCES public.questoes(id) ON DELETE CASCADE,
    resposta_aluno TEXT,
    UNIQUE(aluno_id, questao_id)
);

-- 7. Views para o App Flutter (Só para garantir que existam)
-- O App chama 'alunos', o banco entrega 'students'
CREATE OR REPLACE VIEW public.alunos AS SELECT * FROM public.students;
CREATE OR REPLACE VIEW public.turmas AS SELECT * FROM public.classes;

-- 8. Liberar Acesso (RLS)
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
