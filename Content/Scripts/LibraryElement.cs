using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LibraryElement : ScriptableObject
{
    public Button[] buttons;
    public Function[] functions;

    public string nodeName;
    public string tags;
    public string breadcrumbs;
    public Material material;

    [Multiline(10)] public string description;
    [Multiline(20)] public string usages;

    [System.Serializable]
    public struct Button
    {
        public string name;
        public string url;
        public Object obj;
    }

    [System.Serializable]
    public struct Function
    {
        [Multiline(3)]
        public string function;
        [Multiline(3)]
        public string description;
        public bool showMinMax;
        public float min;
        public float max;
        public string[] properties;
    }
}
