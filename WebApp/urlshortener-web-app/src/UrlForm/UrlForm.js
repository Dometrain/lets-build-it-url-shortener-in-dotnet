import "./UrlForm.css";
import React, { useState } from "react";

function UrlForm({ onSubmit }) {
    const [longUrl, setLongUrl] = useState("");


    const handleSubmit = async (e) => {
        e.preventDefault();
        onSubmit(longUrl);
        setLongUrl("");
    };


    return (
        <form className="url-form" onSubmit={handleSubmit}>
            <input
                type="text"
                placeholder="Enter a long URL"
                value={longUrl}
                onChange={(e) => setLongUrl(e.target.value)}
                className="url-input" />
            <button type="submit" className="shorten-button">
                Shorten
            </button>
        </form>
    );
}

export default UrlForm