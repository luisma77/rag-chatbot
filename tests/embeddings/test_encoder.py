from unittest.mock import patch, MagicMock
import numpy as np


def test_encode_returns_list_of_floats():
    from src.embeddings.encoder import encode
    mock_model = MagicMock()
    mock_model.encode.return_value = np.array([[0.1, 0.2, 0.3] * 128])
    with patch("src.embeddings.encoder._get_model", return_value=mock_model):
        result = encode(["Texto de prueba"])
    assert isinstance(result, list)
    assert isinstance(result[0], list)
    assert isinstance(result[0][0], float)


def test_encode_single_text():
    from src.embeddings.encoder import encode_one
    mock_model = MagicMock()
    mock_model.encode.return_value = np.array([[0.1] * 384])
    with patch("src.embeddings.encoder._get_model", return_value=mock_model):
        result = encode_one("Texto")
    assert isinstance(result, list)
    assert len(result) == 384
