from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.formalism import build_formalism


def main() -> None:
    formalism = build_formalism()
    print("Title:", formalism.title)
    print("Assumptions:", len(formalism.assumptions))
    print("Equations:", len(formalism.core_equations))
    print("Layers:", len(formalism.layers))
    print("Warnings:", len(formalism.warnings))


if __name__ == "__main__":
    main()
