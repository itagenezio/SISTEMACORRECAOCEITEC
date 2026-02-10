const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

try {
    console.log('--- Iniciando Build do Flutter na Vercel ---');

    // 1. Clonar Flutter (se necessário)
    if (!fs.existsSync('flutter')) {
        console.log('Baixando Flutter SDK...');
        execSync('git clone https://github.com/flutter/flutter.git -b stable --depth 1', { stdio: 'inherit' });
    }

    const flutterBin = path.join(process.cwd(), 'flutter', 'bin', 'flutter');

    // 2. Configurar e Buildar
    console.log('Configurando suporte Web...');
    execSync(`${flutterBin} config --enable-web`, { stdio: 'inherit' });

    console.log('Instalando dependências...');
    execSync(`${flutterBin} pub get`, { stdio: 'inherit' });

    console.log('Compilando para Web (Release)...');
    execSync(`${flutterBin} build web --release`, { stdio: 'inherit' });

    // 3. Preparar pasta de saída transparente para a Vercel
    // Movemos de build/web para uma pasta chamada 'public' na raiz
    console.log('Preparando diretório de entrega...');
    const source = path.join(process.cwd(), 'build', 'web');
    const dest = path.join(process.cwd(), 'public');

    if (fs.existsSync(dest)) {
        fs.rmSync(dest, { recursive: true, force: true });
    }

    // Renomeia a pasta para 'public'
    fs.renameSync(source, dest);

    console.log('--- Build concluído com sucesso! Pasta: public ---');
} catch (error) {
    console.error('ERRO NO BUILD:', error);
    process.exit(1);
}
