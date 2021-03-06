/// buildpalette(c1, c2, c3, ...)
/*
    Builds and returns the array of colours Red, Green, Blue channel separated, in 0..1 range
*/
var _arr = -1;
for (var i=0; i<max(argument_count, 16); i++)
{
    var _rgb = c_black;
    if (i < argument_count)
    {
        _rgb = argument[i];
    }
    
    // convert RGB to BGR
    var _idx = array_length_1d(_arr);
    _arr[_idx++] = ((_rgb & $FF0000) >> 16) / 255;
    _arr[_idx++] = ((_rgb & $00FF00) >> 8) / 255;
    _arr[_idx++] = (_rgb & $0000FF) / 255;
}
return _arr;
