-- SCRIPT DE CORREÇÃO URGENTE DA VIEW (FIX_VIEW_MISSING_COLUMN.sql)
-- O erro ocorre porque a View 'turmas' foi criada sem a coluna 'escola_id'.
-- Este script corrige isso instantaneamente.

-- 1. Garantir que a tabela original (CLASSES) tenha a coluna escola_id
ALTER TABLE public.classes ADD COLUMN IF NOT EXISTS escola_id UUID REFERENCES public.escolas(id) ON DELETE SET NULL;

-- 2. Recriar a View TURMAS incluindo a coluna escola_id (ESSENCIAL)
DROP VIEW IF EXISTS public.turmas;

CREATE OR REPLACE VIEW public.turmas AS 
    SELECT 
        id, 
        name as nome, 
        created_at, 
        escola_id 
    FROM public.classes;

-- 3. Recriar a View ALUNOS também para garantir (com todas as colunas)
DROP VIEW IF EXISTS public.alunos;

CREATE OR REPLACE VIEW public.alunos AS 
    SELECT 
        id, 
        name as nome, 
        email, 
        class_id as turma_id, 
        access_code as matricula 
    FROM public.students;

-- 4. Garantir permissões de leitura
GRANT ALL ON public.turmas TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.alunos TO postgres, anon, authenticated, service_role;
