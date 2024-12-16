import "./ListUrls.css"
import React from "react";

function ListUrls({ urls, continuationToken, onLoadMore }) {
    return (
        <div className="url-list">
            {urls && urls.map((url) => (
                <div key={url.shortUrl} className="url-item">
                    {url.shortUrl} → {url.longUrl}
                </div>
            ))}
            {continuationToken && (
                <button onClick={onLoadMore}>Load more</button>
            )}
        </div>
    );
}

export default ListUrls