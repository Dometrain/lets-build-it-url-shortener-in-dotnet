import "./Home.css"
import React, { useState, useEffect } from "react";
import { useMsal } from "@azure/msal-react";
import LogoutButton from "../LogoutButton/LogoutButton";
import ListUrls from "../ListUrls/ListUrls";
import UrlForm from "../UrlForm/UrlForm"
import axios from "axios";

function Home() {

    const scope = `api://${process.env.REACT_APP_CLIENT_ID}/Urls.Read`
    const apiEndpoint = process.env.REACT_APP_API_ENDPOINT;

    const { instance, accounts } = useMsal();
    const [data, setData] = useState({
        initialized: false,
        urls: [],
        continuationToken: null
    })

    const handleLogout = () => {
        instance.logoutRedirect();
    };

    const getToken = async () => {
        const request = {
            scopes: [`openid profile ${scope}`],
            account: accounts[0]
        };
        const response = await instance.acquireTokenSilent(request);
        return response.accessToken;
    };


    const fetchUrls = async () => {
        const token = await getToken();
        const response = await axios.get(`${apiEndpoint}/api/urls`, {
            headers: { Authorization: `Bearer ${token}` },
            params: {
                continuation: data.continuationToken,
                pageSize: 5
            }
        });
        setData(
            prev => (
                {
                    initialized: true,
                    urls: [...prev.urls, ...response.data.urls],
                    continuationToken: response.data.continuationToken
                }));
    };

    const handleLoadMore = () => {
        fetchUrls();
    };

    const handleSubmit = async (longUrl) => {
        const token = await getToken();
        await axios.post(`${apiEndpoint}/api/urls`,
            { LongUrl: longUrl },
            { headers: { Authorization: `Bearer ${token}` } }
        );
    };


    useEffect(() => {
        if (!data.initialized)
            fetchUrls();
    });

    return (
        <div className="container">
            <h1>Dometrain URL Shortener</h1>
            <div className="header">
                <LogoutButton onLogout={handleLogout}></LogoutButton>
            </div>
            <UrlForm onSubmit={handleSubmit} />
            <ListUrls
                urls={data.urls}
                continuationToken={data.continuationToken}
                onLoadMore={handleLoadMore}
            />
        </div>
    );
}

export default Home;